require 'operation/rabbit_mq'

class Operation::RabbitMq::ChangePassword < Operation::RabbitMq
	
	def steps
    steps = super
    
    steps << Operation::Step.new('change_password') do
    
      timeout_in(5.minutes)
  
      provider_account = ProviderAccount.find(self[:args][:provider_account_id])    
      send_rabbitmq_command :change_password, [ 
        provider_account.messaging_username,
        provider_account.messaging_password
      ]
      
      success = true
      self[:result_code] = 'Success'
      self[:result_message] = "Request to change messaging user password for account '#{account.name}'"
    
      operation_logs << OperationLog.new( {
        :step_name => 'change_password',
        :is_success => success,
        :result_code => self[:result_code],
        :result_message => self[:result_message],
      } )
    end
    
    return steps
	end
	
end
