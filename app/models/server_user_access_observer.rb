require 'pp'

class ServerUserAccessObserver < ActiveRecord::Observer

private
	@is_enabled_changed   = false
	@server_user_changed  = false
	@previous_server_user = nil

	def add_key(server, local_user, server_user)
		server.instances.each do |instance|
			next if not instance.running?
			instance.operations << Operation.factory(
					'Operation::SshKeys::Add',
					:args => { :local_user_id => local_user, :server_user => server_user }
			)
		end
	end

	def del_key(server, local_user, server_user)
		server.instances.each do |instance|
			next if not instance.running?
			instance.operations << Operation.factory(
					'Operation::SshKeys::Delete',
					:args => { :local_user_id => local_user, :server_user => server_user }
			)
		end
	end

public

	def after_create(user_access)
		add_key(user_access.server, user_access.user_id, user_access.server_user)
	end

	def before_update(user_access)
		@is_enabled_changed  = user_access.is_enabled_changed?
		@server_user_changed = user_access.server_user_changed?

		if @server_user_changed
			@previous_server_user = user_access.server_user_was
		end
	end

	def after_update(user_access)
		if @is_enabled_changed
			case user_access.is_enabled.to_i
				when 0: del_key(user_access.server, user_access.user_id, user_access.server_user)
				when 1: add_key(user_access.server, user_access.user_id, user_access.server_user)
			end
		end

		if @server_user_changed and user_access.is_enabled.to_i != 0
			# remove user's access to the previous server user
			del_key(user_access.server, user_access.user_id, user_access.server_user)
			# and then add access to the new user
			add_key(user_access.server, user_access.user_id, user_access.server_user)
		end
	end

	def after_destroy(user_access)
		del_key(user_access.server, user_access.user_id, user_access.server_user)
	end
end
