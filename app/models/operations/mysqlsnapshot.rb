require "models/volume"

class Operations::Mysqlsnapshot < Operation
  def self.label
    'MySQL Snapshot'
  end

  def self.is_schedulable?
    true
  end  

  def timeout
    5.minutes
  end

  def task_verify_message
    'Performing a MySQL Snapshot requires that a WRITE LOCK be set on the database.'
  end  

  def steps()
    steps = super || []
    steps += pre_snapshot_steps || []
    steps += snapshot
    steps += post_snapshot_steps || []
    steps
  end
  
  def pre_snapshot_steps
    steps << Operation::Step.new('request_lock_mysql') do
      success = false

      timeout_in(timeout)
      send_request(instance_request_path(instance), :mysql, :lock, database_info)
      
      success = true
      self[:result_code] = 'Success'
      self[:result_message] = 'Sent message to lock the database'

      operation_logs << OperationLog.new( {
        :step_name => 'request_lock_mysql',
        :is_success => success,
        :result_code => self[:result_code],
        :result_message => self[:result_message],
      } )
    end

    steps << Operation::Step.new('check_lock_mysql_response') do
      success = false

      message = get_response_for_message("mysql")

      # Make sure we got a response message
      if message.nil?
        self[:result_code] = 'ClientError'
        self[:result_message] = 'Unable to find response to lock request.'
      elsif message.message != 'Locked'
        # Make sure the operation succeeded.
        self[:result_code] = 'ClientError'
        self[:result_message] = 'MySQL Lock handler did not return a proper response.'
      else
        success = true
        self[:result_code] = 'Success'
        self[:result_message] = 'Instance replied: Database lock was successful'
      end

      operation_logs << OperationLog.new( {
        :step_name => "check_response",
        :is_success => success,
        :result_code => self[:result_code],
        :result_message => self[:result_message],
      } )
      
      unless success
        fail! && next
      end
      proceed! if not failed?
    end

    steps << Operation::Step.new('create_erb_snapshot') do
      success = true

      #Find EBSes for this instance:
      volumes = CloudVolume.find_all_by_instance_id(instance.id)

      # snapshot all volumes
      error_messages = []
      snapshots = []
      volumes.each do |volume|
        snapshot = nil
        error_message = ''
        begin
          snapshot = volume.snapshot!(suffix)
        rescue Exception => e
			error_msg = "Failed to snapshot volume '#{volume.name}' [#{volume.id}]: #{e.message}"
    		Rails.logger.error msg+"\n\t#{e.backtrace.join("\n\t")}"
        end
        if snapshot.nil?
            error_msg = "Failed to snapshot volume '#{volume.name}' [#{volume.id}]: #{volume.errors.collect{|attr, msg| "#{attr.huminize} - #{msg}" }}"
        else
            snapshots << snapshot
        end
		error_messages << error_msg unless error_msg.blank?
      end
      
      if error_messages.empty?
          success = true
          self[:result_code] = 'Success'
          self[:result_message] = "Created snapshot(s) #{snapshots.collect{|s| "'"+s.name+"'"}.join(", ")}"
      else
          self[:result_code] = 'ClientError'
          self[:result_message] = 'There was an error creating the snapshot(s): '+error_messages.join("\n ")
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

    steps << Operation::Step.new('request_unlock_mysql') do
      success = false
      
      timeout_in(timeout)
      
      send_request(
        instance_request_path(instance),
        :mysql, :unlock, database_info[0,3] # only need host, user, pass here
      )

      success = true
      self[:result_code] = 'Success'
      self[:result_message] = 'Sent message to unlock the database'

      operation_logs << OperationLog.new( {
        :step_name => 'request_unlock_mysql',
        :is_success => success,
        :result_code => self[:result_code],
        :result_message => self[:result_message],
      } )
    end

    steps << Operation::Step.new('check_unlock_mysql_response') do
      success = false

      message = get_response_for_message("unlock_mysql")

      # Make sure we got a response message
      if message.nil?
        self[:result_code] = 'ClientError'
        self[:result_message] = 'Unable to find response to ready request'
      elsif message.message != 'Unlocked'
        # Make sure the operation succeeded.
        # It's an error if the database was unlocked before we locked it.
        # (i.e.: our timeout is too short, and we may have a corrupted DB image.)
        self[:result_code] = 'ClientError'
        msg = "Database was unlocked already!"
        msg << " The snapshot is probably corrupt. "
        msg << " (Our timeout may be too short.)"
        self[:result_message] = msg
      else
        success = true
        self[:result_code] = 'Success'
        self[:result_message] = 'Instance replied: Database unlock was successful'
      end

      operation_logs << OperationLog.new( {
        :step_name => 'check_response',
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

  private
  
  def database_info()
    s = server

    # Really, host should always be localhost since we're taking a snapshot of the image.
    host = s.get_server_parameter("MYSQL_LOCK_HOST") ||  "localhost"
    user = s.get_server_parameter("MYSQL_LOCK_USER")
    password = s.get_server_parameter("MYSQL_LOCK_PASS")
    coordinates_file = s.get_server_parameter("MYSQL_COORDINATES_FILE")
    
    raise "MYSQL_LOCK_USER Server param must be set!" if user.nil?
    raise "MYSQL_LOCK_PASS Server param must be set!" if password.nil?
  
    [ host, user, password, timeout, coordinates_file ]
  end

  
end
