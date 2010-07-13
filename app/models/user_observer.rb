class UserObserver < ActiveRecord::Observer

	def after_create(user)
		add_pubkey_to_servers(user) if not user.public_key.blank?
	end

	def after_destroy(user)
		delete_pubkey_from_servers(user)
	end

	def after_save(user)
		UserMailer.deliver_activation(user) if user.recently_activated?
		UserMailer.deliver_forgot_password(user) if user.recently_forgot_password?
		UserMailer.deliver_reset_password(user) if user.recently_reset_password?
		UserMailer.deliver_signup_notification(user) if (user.recently_created? || user.lost_activation_code?)
	end

	def before_update(user)
		@pubkey_changed = user.public_key_changed?
		delete_pubkey_from_servers(user) if user.public_key_changed?
	end

	def after_update(user)
		add_pubkey_to_servers(user) if @pubkey_changed and not user.public_key.blank?
	end

private
	@pubkey_changed = false

	def add_pubkey_to_servers(user)
		suas = ServerUserAccess.find_all_by_user_id(user.id)
		unless suas.nil?
			suas.each do |sua|
				add_key(sua.server_id, user.id, sua.server_user)
			end
		end
	end

	def delete_pubkey_from_servers(user)
		suas = ServerUserAccess.find_all_by_user_id(user.id)
		unless suas.nil?
			suas.each do |sua|
				add_key(sua.server_id, user.id, sua.server_user)
			end
		end
	end

	def add_key(server, local_user, server_user)
		server = Server.find_by_id(server) if server.is_a? Fixnum
		return unless server.is_a? Server

		server.instances.each do |instance|
			next if not instance.running?
			instance.operations << Operation.factory(
					'Operations::SshKeys::Add',
					:args => { :local_user_id => local_user, :server_user => server_user }
			)
		end
	end

	def del_key(server, local_user, server_user)
		server = Server.find_by_id(server) if server.is_a? Fixnum
		return unless server.is_a? Server

		server.instances.each do |instance|
			next if not instance.running?
			instance.operations << Operation.factory(
					'Operations::SshKeys::Delete',
					:args => { :local_user_id => local_user, :server_user => server_user }
			)
		end
	end
end
