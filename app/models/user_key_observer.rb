class UserKeyObserver < ActiveRecord::Observer
    def after_create(user_key)
        self.class.add_user_key_to_servers(user_key) if not user_key.public_key.blank? and user_key.user.enabled?
    end

    def after_destroy(user_key)
        self.class.delete_user_key_from_servers(user_key)
    end

    def before_update(user_key)
        @public_key_changed = user_key.public_key_changed?
        self.class.delete_user_key_from_servers(user_key) if @public_key_changed
    end

    def after_update(user_key)
        self.class.add_user_key_to_servers(user_key) if @public_key_changed and not user_key.public_key.blank? and user_key.user.enabled?
    end

    @public_key_changed = false

    def self.add_user_key_to_servers(user_key)
        suas = ServerUserAccess.find_all_by_user_id(user_key.user_id, :include => :server)
	unless suas.nil?
	    suas.each do |sua|
		sua.server.add_user_key(user_key, sua.server_user)
	    end
	end
	servers = Server.find_all_by_user(user_key.user_id)
	servers.each do |server|
	    server.add_user_key(user_key, 'root')
	end
    end

    def self.delete_user_key_from_servers(user_key)
        suas = ServerUserAccess.find_all_by_user_id(user_key.user_id, :include => :server)
        unless suas.nil?
	    suas.each do |sua|
		sua.server.delete_user_key(user_key, sua.server_user)
	    end
	end
	servers = Server.find_all_by_user(user_key.user_id)
	servers.each do |server|
	    server.delete_user_key(user_key, 'root')
	end
    end
end
