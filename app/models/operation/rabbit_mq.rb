class Operation::RabbitMq < Operation
	def self.label
		'RabbitMQ'
	end

	def self.is_schedulable?
		false
	end


  def account
    unless (self[:args][:provider_account_id] rescue nil).nil?
      self[:args][:provider_account_id]
    else
      super
    end
  end
end
