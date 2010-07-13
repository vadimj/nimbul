class ServerResourceMountType
    # overwrite this method to provide another allocation mechanism
    def self.allocate!(cloud_resource, zone=nil)
        # check the type
        self.support_cloud_resource?(cloud_resource) do |result, msg|
            unless result
                yield nil, msg
                return
            end
        end
        
		yield cloud_resource, "#{cloud_resource.short_type} '#{cloud_resource.name}' allocated"
    end
    
    def self.cloud_resource_types
        raise 'cloud_resource_types should be overwritten in subclasses of ServerResourceMountType'
    end

    def self.care_about_zone?
        raise 'care_about_zone? should be overwritten in subclasses of ServerResourceMountType'
    end
    
    def self.allow_multiple_allocations?
        raise 'allow_multiple_allocations? should be overwritten in subclasses of ServerResourceMountType'
    end
    
    def self.can_mount?(mountee, cloud_resource, allow_multiple_allocations=false)
        # check the type
        self.support_cloud_resource?(cloud_resource) do |result, msg|
            unless result
                yield false, msg
                return
            end
        end
        
        choose_another_or_request_msg = "Choose another #{cloud_resource.short_type} or request more #{cloud_resource.short_types} from the Account Administrator."
        
        # check to make sure the mounter can mount given the zones
        if self.care_about_zone?
            if mountee.zone_id.nil?
                yield false, "Mounter '#{self.name}' cannot be used for a #{mountee.mountee_class_name} without a zone. Create another #{mountee.mountee_class_name} within a specific zone."
                return
            elsif mountee.zone_id != cloud_resource.zone_id
                rb_zone_name = mountee.zone_id.blank? ? 'undefined' : mountee.zone.name
                cr_zone_name = cloud_resource.zone_id.blank? ? 'undefined' : cloud_resource.zone.name
                yield false, "Mounter '#{self.name}' will not be able to mount #{cloud_resource.short_type} '#{cloud_resource.name}' because #{mountee.mountee_class_name}'s zone '#{rb_zone_name}' doesn't match #{cloud_resource.short_type}'s zone '#{cr_zone_name}'. #{choose_another_or_request_msg}"
                return
            end
        end
        
        # if the mounter cares - check to make sure this resource is not allocated already
        unless allow_multiple_allocations or self.allow_multiple_allocations?
    		server = mountee.server
    		allocated_resource_ids = []
    		# grab this server's allocated resources that don't allow multiple allocations
    	    server.resource_bundles.each do |rs|
    			allocated_resource_ids += rs.server_resources.collect{ |v| v.cloud_resource_id unless v.mount_type.constantize.allow_multiple_allocations? }.compact
    	    end
    	    if allocated_resource_ids.include?(cloud_resource.id)
                yield false, "#{cloud_resource.short_type} '#{cloud_resource.name}' is already allocated by another #{mountee.mountee_class_name} of this server. #{choose_another_or_request_msg}"
                return
    	    end
        end
	    
        yield true, ''
    end
    
	def self.name() return self.to_s.gsub('MountType','').titleize; end

    def self.support_cloud_resource?(cloud_resource)
        if cloud_resource_types.include?(cloud_resource.class_type)
            yield true, ''
        else
            yield false, "Mounter '#{self.name}' doesn't support '#{cloud_resource.class_type}'. Supported resource type(s): #{self.cloud_resource_types.join(', ')}"
        end
        return
    end
end
