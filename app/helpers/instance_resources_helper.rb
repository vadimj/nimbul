module InstanceResourcesHelper
    def add_instance_address_link(text, instance)
        link_to_function text do |page|
            page[:add_address].hide
            page[:new_address].appear
        end
    end
    
    def cancel_add_instance_address_button(text, instance)
        button_to_function text do |page|
            page[:new_address].hide
            page[:add_address].appear
        end
    end
    
    def add_instance_volume_link(text, instance)
        link_to_function text do |page|
            page[:add_volume].hide
            page[:new_volume].appear
        end
    end
    
    def cancel_add_instance_volume_button(text, instance)
        button_to_function text do |page|
            page[:new_volume].hide
            page[:add_volume].appear
        end
    end
    
    def instance_resource_force_allocation_check_box(instance, instance_resource)
		msg = 'Are you sure you want to force allocation of this Volume?\n\n'
		msg += "The detachment will be forced if the previous detachment attempt did not occur cleanly "
		msg += "(logging into an instance, unmounting the volume, and detaching normally). This option "
		msg += "can lead to data loss or a corrupted file system. Use this option only as a last resort "
		msg += "to detach a volume from a failed instance. The instance will not have an opportunity to "
		msg += "flush file system caches nor file system metadata. If you use this option, you must "
		msg += "perform file system check and repair procedures."

        title = "If checked, this #{instance_resource.short_type} will be moved to a new instance even if it is already associated with a running instance."
        name = "instance_resource_#{instance_resource.id}_force_allocation"
        
		# additional warning for forced re-allocation of volumes
        confirm = nil
        if instance_resource.is_a?(InstanceVolume) and !instance_resource.force_allocation?
			confirm = msg
        end

		if instance_resource.state == 'attached'
			options = {
				:disabled => true
			}
		else
			function_options = {
                :url => instance_instance_resource_url(instance, instance_resource),
                :with => "'instance_resource[force_allocation]='+( $('#{name}').checked == true ? 1 : 0 )",
                :method => :put
			}
			unless confirm.nil?
				function_options.merge!({
					:before => "if(!confirm('#{confirm}')) return false;"
				})
			end
			options = {
				:onclick => remote_function(function_options)
			}
		end
		
		options.merge!({ :title => title })
		check_box_tag name, 1, instance_resource.force_allocation?, options
    end

   	def attach_instance_resource_link(text, instance, instance_resource)
		return '' if instance_resource.state == 'attached'
		title = "Attach #{instance_resource.short_type} '#{instance_resource.cloud_resource.name}'"
		title += " as #{instance_resource.mount_point}" unless instance_resource.mount_point.blank?

		link_text = image_tag("acquire.png", :class => 'control-icon', :alt => text)
		url = attach_instance_instance_resource_url(instance, instance_resource)
    	options = {
            :url => url,
            :method => :get,
		}
		html_options = {
			:title => title,
            :href => url,
            :method => :get,
		}
		link_to_remote link_text, options, html_options
	end

   	def detach_instance_resource_link(text, instance, instance_resource)
		return '' unless instance_resource.state == 'attached'
		link_text = image_tag("release.png", :class => 'control-icon', :alt => text)
		url = detach_instance_instance_resource_url(instance, instance_resource)
    	options = {
            :url => url,
            :method => :get,
		}
		html_options = {
			:title => "Detach #{instance_resource.short_type} '#{instance_resource.cloud_resource.name}'",
            :href => url,
            :method => :get,
		}
		link_to_remote link_text, options, html_options
	end

   	def remove_instance_resource_link(text, instance, instance_resource)
		return '' if instance_resource.state == 'attached'
		msg = "allocation of #{instance_resource.short_type} '#{instance_resource.cloud_resource.name}'"
		title = "Remove #{msg}"
		confirm = "Are you sure you want to remove #{msg}?"
		link_text = image_tag("trash.png", :class => 'control-icon', :alt => text)
		url = instance_instance_resource_url(instance, instance_resource)
    	options = {
			:confirm => confirm,
            :url => url,
            :method => :delete,
		}
		html_options = {
			:title => title,
            :href => url,
            :method => :delete,
		}
		link_to_remote link_text, options, html_options
	end
end
