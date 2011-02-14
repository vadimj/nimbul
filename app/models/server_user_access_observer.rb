require 'pp'

class ServerUserAccessObserver < ActiveRecord::Observer

private
  @is_enabled_changed   = false
  @server_user_changed  = false
  @previous_server_user = nil

public
  def after_create(user_access)
    user = User.find(user_access.user_id, :include => :user_keys)
    user.user_keys.each do |user_key|
      user_access.server.add_user_key(user_key, user_access.server_user)
    end
  end

  def before_update(user_access)
    @is_enabled_changed  = user_access.is_enabled_changed?
    @server_user_changed = user_access.server_user_changed?

    if @server_user_changed
      @previous_server_user = user_access.server_user_was
    end
  end

  def after_update(user_access)
    user = User.find(user_access.user_id, :include => :user_keys)

    if @is_enabled_changed
      user.user_keys.each do |user_key|
        user_access.server.add_user_key(user_key, user_access.server_user) if user_access.is_enabled?
        user_access.server.delete_user_key(user_key, user_access.server_user) if not user_access.is_enabled?
      end
    end
    
    if @server_user_changed and user_access.is_enabled?
      user.user_keys.each do |user_key|
	# remove user's access to the previous server user
        user_access.server.delete_user_key(user_key, @previous_server_user)
        # and then add access to the new user
        user_access.server.add_user_key(user_key, user_access.server_user)
      end
    end
  end

  def after_destroy(user_access)
    user = User.find(user_access.user_id, :include => :user_keys)
    user.user_keys.each do |user_key|
      user_access.server.delete_user_key(user_key, user_access.server_user)
    end
  end
end
