require "models/volume"
require "models/ec2_adapter"

class Operation::Snapshot < Operation
  
  def self.label
    'EBS Snapshot'
  end

  def self.is_schedulable?
    true
  end  

  def timeout
    5.minutes
  end

  def steps()
    steps = []
    steps += pre_snapshot_steps || []
    steps += [ snapshot_step ].compact.flatten
    steps += post_snapshot_steps || []
    steps
  end
  
  def pre_snapshot_steps() nil; end
  def post_snapshot_steps() nil; end
  
  def snapshot_step
    Operation::Step.new('create_erb_snapshot') do
      success = false

      #Find EBSes for this instance:
      volumes = CloudVolume.find_all_by_instance_id(instance.id)

      volumes.each do |volume|
        snapshot = volume.snapshot!
        if snapshot.nil?
          self[:result_code] = 'ClientError'
          self[:result_message] = 'There was an error creating the snapshot: '+volume.errors.collect{|attr,msg| "#{attr} - #{msg}" }.join("; ")
        else
          success = true
          self[:result_code] = 'Success'
          self[:result_message] = "Created snapshot: #{snapshot.name}"
        end
      end

      operation_logs << OperationLog.new( {
        :step_name => 'create_erb_snapshot',
        :is_success => success,
        :result_code => self[:result_code],
        :result_message => self[:result_message],
      } )
      
      unless success
        fail! && next
      end
      proceed! if not failed?
    end
  end
end
