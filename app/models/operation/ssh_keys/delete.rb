require 'operations/ssh_keys'

class Operation::SshKeys::Delete < Operation::SshKeys
  def initiate_failure() super; update_server_user_access(self[:result_message]); end
  def initiate_timeout() super; update_server_user_access(self[:result_message]); end

    def initiate_success()
        super
        user = User.find(self[:args][:local_user_id])
        update_attributes({
            :result_code => 'Success_RemovePublicKey',
            :result_message => "#{user.login}'s public key has been removed for instance user #{self[:args][:server_user]}",
        })
    end

  def steps
    steps = super

    steps << Operation::Step.new('delete') do

      timeout_in(5.minutes)

      user = User.find_by_id(self[:args][:local_user_id])

      if user.nil?
        self[:result_code] = 'Error_InvalidUserID'
        self[:result_message] = "User ID #{self[:args][:local_user_id]} is invalid - the user doesn't exist."
        fail! && next
      end

      if user.public_key.length <= 0
        self[:result_code] = 'Error_MissingPublicKey'
        self[:result_message] = "#{user.login} is missing a public key"
        fail! && update_server_user_access(self[:result_message]) && next
      end

      send_request(
        instance_request_path(instance),
        :sshkeys, :delete, [ self[:args][:server_user], user.public_key ]
      )

      success = true
      self[:result_code] = 'Success'
      self[:result_message] = "Request to remove user ssh public key sent."

      operation_logs << OperationLog.new( {
        :step_name => 'add',
        :is_success => success,
        :result_code => self[:result_code],
        :result_message => self[:result_message],
      } )
    end

    # at this step we should have received back a fully encrypted message with correct signature, etc.
    steps << Operation::Step.new('verify_key_deletion') do # local
      message = get_response_by_handler('sshkeys')

      # Make sure we got a response message
      if message.nil?
        success = false
        self[:result_code] = 'ClientError'
        self[:result_message] = 'Unable to verify response to ping request.'
      else
        if message.status == 'ok'
          success = true
          self[:result_code] = 'Success'
          self[:result_message] = message.message || "Instance successfully removed key."
        else
          success = false
          self[:result_code] = 'ClientError'
          self[:result_message] = message.message
        end
      end

      operation_logs << OperationLog.new({
          :step_name => "verify_key_deletion",
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
