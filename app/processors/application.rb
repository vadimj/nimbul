class ApplicationProcessor < ActiveMessaging::Processor
  
  attr_reader :operation, :stored_message, :account
  
  def initialize
    @stored_message = nil
    @operation = nil
    super
  end
  
  def process!(message)
    @stored_message = store_message(message)
    @operation = get_operation(message)
    @account = ProviderAccount.find(message.account) rescue nil
    
    super(message)

    if @operation.nil?
      text = "Message #{stored_message.message_id} has no Operation waiting for it"
      puts text
      Rails.logger.error text
      @stored_message.message = text
      @stored_message.state = 'error'
      @stored_message.save
      return 
    end

    case true
      when stored_message.bounced?
        @operation.result_code = 'ClientError_MissingHandler'
        @operation.result_message = message.message
        @operation.fail!

      when stored_message.errored?
        @operation.result_code = 'ClientError_General'
        @operation.result_message = message.message
        @operation.next_attempt!

      when stored_message.ok?
        @operation.proceed! if @operation.can_proceed?
    end
  end
  
  # Default on_error implementation - logs standard errors but keeps processing. Other exceptions are raised.
  # Have on_error throw ActiveMessaging::AbortMessageException when you want a message to be aborted/rolled back,
  # meaning that it can and should be retried (idempotency matters here).
  # Retry logic varies by broker - see individual adapter code and docs for how it will be treated
  def on_error(err)
    if (err.kind_of?(StandardError))
      logger.error "ApplicationProcessor::on_error: #{err.class.name} rescued:\n" + \
      err.message + "\n" + \
      "\t" + err.backtrace.join("\n\t")
    else
      logger.error "ApplicationProcessor::on_error: #{err.class.name} raised: " + err.message
      raise err
    end
  end
  
  private
  
  def store_message(msg)
    message = ProviderAccount.find(msg.account).in_messages.build({
      :sender       => msg.replyto || msg.sender,
      :recipient    => msg.recipient,
      :message_id   => msg.thread,
      :operation_id => msg.operation,
      :status       => msg.status_type,
      :message      => msg.status_note, 
      :state        => :new,
      :data         => YAML.dump(msg.data),
      :handler      => msg.agent,
      :sent_at      => DateTime.parse(Time.at(msg.time[:sent]).to_s),
      :received_at  => DateTime.parse(Time.at(msg.time[:received]).to_s)
    })
    message.save
    message
  end
  
  def get_operation(message)
    Operation.find(:first,
      :conditions => [ 'id = ? and state = ?', message.headers[:operation], :waiting ]
    )
  end
end