class Operations::SshKeys < Operation
  def steps() super; end
  def max_attempts() super; end
  def initiate_failure() super; end

    def self.label
        'Key Manager'
    end

    def self.is_schedulable?
        false
    end

private

  def update_server_user_access(status_message='Unknown')
    server_id   = instance[:server_id]
    user_id     = self[:args][:local_user_id]
    server_user = self[:args][:server_user]

    sua = ServerUserAccess.find_by_server_id_and_user_id_and_server_user(server_id, user_id, server_user)
    unless sua.nil?
      ServerUserAccess.delete_observers
      sua.update_attribute(:status_message, status_message)
    end
  end

end
