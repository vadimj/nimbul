require "models/volume"

class Operation::Snapshot::Purge < Operation

  def timeout
    5.minutes
  end

  def self.label
    'Purge Snapshots'
  end

  def self.is_schedulable?
    true 
  end  

  def operation_parameters
    s = server
    keep_snapshots = s.get_server_parameter('KEEP_SNAPSHOTS')
    raise 'KEEP_SNAPSHOTS parameter must be set for this Server Profile and must be an Integer!' if keep_snapshots.blank? || (keep_snapshots.to_i == 0)
    return {
        :keep_snapshots => keep_snapshots.to_i
    }
  end

  def steps()
    steps = super || []

    steps << Operation::Step.new('create_erb_snapshot') do
      success = false
      #Find EBSes for this instance:
      volumes = CloudVolume.find_all_by_instance_id(instance.id)

      if volumes.blank?
        self[:result_code] = 'ClientError'
        self[:result_message] = "This instance doesn't appear to have any Volumes attached."
      else
        volumes.each do |volume|
          if volume.nil?
            self[:result_code] = 'ClientError'
            self[:result_message] = "This instance doesn't appear to have a Volume attached."
          else
            snapshots = CloudSnapshot.find_all_by_provider_account_id_and_parent_cloud_id(volume.provider_account_id, volume.cloud_id, :order => 'start_time')
            # make sure we deal with completed snapshots only
            snapshots.collect!{|a| a if a.status == 'completed'}.compact!
            if snapshots.length <= keep_snapshots
              self[:result_code] = 'ClientError'
              self[:result_message] = "Not enough (#{snapshots.length}) complete snapshots to purge and keep #{keep_snapshots}."
            else
              purge_snapshots = snapshots[0, snapshots.length - keep_snapshots]
              begin
                purge_snapshots.each do |s|
                  s.delete!
                end
                success = true 
                self[:result_code] = 'Success'
                self[:result_message] = "Purged all snapshots of Volume '#{volume.name}' except last #{keep_snapshots}."
              rescue
                success = false
                self[:result_code] = 'ClientError'
                self[:result_message] = "There was an error purging snapshots of Volume '#{volume.name}': #{$!}."
              end
            end
          end
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
