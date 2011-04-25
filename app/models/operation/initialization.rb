class Operation::Initialization < Operation
  def max_attempts() 3; end

  def self.label
    'Initialization'
  end

  def self.is_schedulable?
    false
  end

  def steps()
    steps = super || []
    
    steps << Operation::Step.new('import_instance_data') do # local

      instance.private_ip = self[:args][:local_ip]
      instance.public_ip  = self[:args][:public_ip]
      instance.save
      
      success = true
      self[:result_code] = 'Success'
      self[:result_message] = 'Imported New Instance Data'

      instance.is_ready = true

      # vadimj: if instance replied and is ready - it must be in running state!
      # this will ensure the new instances will get dns even if slow refresh
      # daemon haven't updated their state to 'running' yet
      instance.state = 'running'
      instance.save

      operation_logs << OperationLog.new({
        :step_name => 'import_instance_data',
        :is_success => success,
        :result_code => self[:result_code],
        :result_message => self[:result_message],
      })

      proceed! if not failed?
    end

    # here we're sending out a fully encrypted message that the instance /should/ be able to
    # unencrypt, and perform signature verification on.
    steps << Operation::Step.new('ping_instance') do # remote
      timeout_in 5.minutes
      send_request instance_request_path(instance), :ping, :ping

      success = true
      self[:result_code] = 'Success'
      self[:result_message] = 'Sent Ping request to instance.'

      operation_logs << OperationLog.new( {
        :step_name => 'ping_instance',
        :is_success => success,
        :result_code => self[:result_code],
        :result_message => self[:result_message],
      } )
    end

    # at this step we should have received back a fully encrypted message with correct signature, etc.
    steps << Operation::Step.new('verify_pong') do # local
      puts "Verifying pong"
      Rails.logger.error "Verifying Pong"
      message = get_response_by_handler('ping')

      # Make sure we got a response message
      if message.nil?
        success = false
        self[:result_code] = 'ClientError'
        self[:result_message] = 'Unable to verify response to ping request.'
      else
        success = true
        self[:result_code] = 'Success'
        self[:result_message] = "Instance replied with pong"
      end

      operation_logs << OperationLog.new({
          :step_name => "verify_pong",
          :is_success => success,
          :result_code => self[:result_code],
          :result_message => self[:result_message],
      })

      unless success
        fail! && next
      else
        succeed!
      end
    end

    return steps
  end
end
