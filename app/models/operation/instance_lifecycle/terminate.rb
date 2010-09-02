class Operation::InstanceLifecycle::Terminate < Operation::InstanceLifecycle
  def self.label
    'Terminate Instances'
  end

  def self.is_schedulable?
    true 
  end

  def timeout
    5.minutes
  end

  def initialize_parameters
    parameters = []
    parameters << TaskParameter.new({
      :name => 'keep_instances',
      :description => 'Specifies the maximum (per server) number of instances to keep. Any extra instances will be terminated when the task is run.',
      :value_type => 'Integer',
      :regex => '/\d+/',
      :is_required => true,
      :custom_value => '0',
    })
    return parameters
  end
  
  def operation_parameters
    ps = {}
    unless self.task.nil?
      self.task.task_parameters.each do |tp|
        value = tp.value
        value = value.to_i if tp.value_type == 'Integer'
        ps[tp.name.to_sym] = value
      end
    end
    return ps
  end

  def steps()
    keep_instances = operation_parameters[:keep_instances]
    
    steps = super || []

    steps << Operation::Step.new('terminate_instances') do
      success = false
      instances = Instance.find_all_by_server_id_and_state(server.id, 'running')

      if instances.length <= operation_parameters[:keep_instances]
        success = true 
        self[:result_code] = 'Success'
        self[:result_message] = "Already running no more than #{keep_instances} instance(s)."
      else
        begin
          instance.unlock!
          instance.terminate!
          success = true 
          self[:result_code] = 'Success'
          self[:result_message] = "Terminated by #{self.task.name}. Keeping at least #{keep_instances} instance(s) running."
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
