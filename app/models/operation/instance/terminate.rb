require "models/instance"

class Operation::Instance::Terminate < Operation
  def timeout
    5.minutes
  end

  def self.label
    'Terminate Instances'
  end

  def self.is_schedulable?
    true 
  end  

  def operation_parameters
    s = server
    keep_instances = s.get_server_parameter('KEEP_INSTANCES') || 0
    return {
        :keep_instances => keep_instances.to_i
    }
  end

  def steps()
    steps = super || []

    steps << Operation::Step.new('terminate_instances') do
      success = false
      instances = Instance.find_all_by_server_id_and_state(server.id, 'running')

      if instances.length <= keep_instances
        success = true 
        self[:result_code] = 'Success'
        self[:result_message] = "Already running no more than #{keep_instances} instances."
      else
        terminate_instances = instances[0, instances.length - keep_instances]
        begin
          terminate_instances.each do |i|
            i.unlock!
            i.terminate!
          end
          success = true 
          self[:result_code] = 'Success'
          self[:result_message] = "Terminated #{terminate_instances.length} instances and kept #{keep_instances} instances running."
        rescue
          success = false
          self[:result_code] = 'ClientError'
          self[:result_message] = "There was an error terminating instances of server '#{server.name}': #{$!}."
        end
      end

      operation_logs << OperationLog.new( {
        :step_name => @name,
        :is_success => success,
        :result_code => self[:result_code],
        :result_message => self[:result_message],
      } )
      
      unless success
        fail! && next
      end
      proceed! if not failed?
    end

    return steps
  end

end
