require 'operation/rabbit_mq'

class Operation::RabbitMq::DelNodeAccount < Operation::RabbitMq
	
	def steps
    steps = super
    
    steps << Operation::Step.new('delete_user') do
    
      timeout_in(5.minutes)

      raise ArgumentError, "Missing required :username argument!" unless self[:args][:username]
      
      send_rabbitmq_command :delete_user, [ self[:args][:username] ]
      
      success = true
      self[:result_code] = 'Success'
      self[:result_message] = "Request to delete messaging user for account '#{account.name}'"
    
      operation_logs << OperationLog.new( {
        :step_name => 'delete_user',
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
