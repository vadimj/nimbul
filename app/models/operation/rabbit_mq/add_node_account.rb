require 'operation/rabbit_mq'

class Operation::RabbitMq::AddNodeAccount < Operation::RabbitMq
	
	def steps
    steps = super
    
    steps << Operation::Step.new('add_user') do
    
      timeout_in(5.minutes)
  
      provider_account = ProviderAccount.find(self[:args][:provider_account_id])    
      send_rabbitmq_command :add_node_account, [ 
        provider_account.messaging_username,
        provider_account.messaging_password,
        provider_account.id
      ]
      
      success = true
      self[:result_code] = 'Success'
      self[:result_message] = "Request to add user credentials for account '#{provider_account.name}'"
    
      operation_logs << OperationLog.new( {
        :step_name => 'add_user',
        :is_success => success,
        :result_code => self[:result_code],
        :result_message => self[:result_message],
      } )

      unless success
        fail! && next
      else
        succeed!
      end
    end
    
    return steps
	end
	
end
