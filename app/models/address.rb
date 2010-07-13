class Address < BaseModel
	belongs_to :provider_account

	validates_presence_of :name
	validates_uniqueness_of :name, :scope => :provider_account_id

	after_save :update_instances, :update_servers

    attr_accessor :should_destroy

    def should_destroy?
        should_destroy.to_i == 1
    end

    def enable!
        update_attribute(:is_enabled, true)
    end

    def disable!
        update_attribute(:is_enabled, false)
    end

    # for better performance, update dependent objects with the new name
    def update_instances
        Instance.update_all( ['public_ip=NULL, dns_name=NULL'], ['provider_account_id=? and public_ip=? and instance_id != ?', provider_account_id, public_ip, instance_id ] )
    	Instance.update_all( ['public_ip=?, dns_name=?', public_ip, name], ['provider_account_id=? and instance_id=?', provider_account_id, instance_id ] )
    end

    def update_servers
    	Server.update_all( ['dns_name=?', name], ['public_ip=?', public_ip ] )
    end

    # sort, search and paginate parameters
    def self.per_page
        10
    end

    def self.sort_fields
        %w(name public_ip instance_id state is_enabled)
    end

    def self.search_fields
        %w(name public_ip instance_id state)
    end

end
