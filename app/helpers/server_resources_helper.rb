module ServerResourcesHelper
    def add_server_resource_link(text, resource_bundle, server_resource_type)
        url = send("new_resource_bundle_#{server_resource_type.underscore}_path", resource_bundle)
		link_text = text
		# add parameters
		with = nil
		ps = []
		ps << "'class_type=#{server_resource_type}'"
		ps << "'zone_id=#{resource_bundle.zone_id}'" unless resource_bundle.zone_id.nil?
		if ps.size > 0
			with = ps.join(" + '&amp;' + ")
		end
		options = {
			:url => url,
			:method => :get,
			:with => with,
		}
		html_options = {
		    :href => url,
		    :method => :get,
		}
        link_to_remote link_text, options, html_options
    end
    
	def cancel_add_server_resource_link(text, resource_bundle, server_resource_type)
        link_to_function text do |page|
            page["add_resource_bundle_#{resource_bundle.id}_#{server_resource_type.underscore}"].replace_html :partial => "resource_bundle/#{server_resource_type.tableize}/add", :locals => { :resource_bundle => resource_bundle }
        end
    end

   	def remove_server_address_link(text, resource_bundle, address)
		url = resource_bundle_server_address_url(resource_bundle, address)
    	options = {
            :url => url,
            :method => :delete,
            :confirm => "You sure you want to remove this address from this launch configuration?\n\nThis action cannot be undone.",
		}
		html_options = {
			:title => "Remove address '#{address.cloud_resource.name}' from this launch configuration",
            :href => url,
            :method => :delete,
		}
		link_to_remote text, options, html_options
	end

    def server_address_force_allocation_check_box(resource_bundle, address)
        title = 'If checked, this address will be moved to a new instance even if it is already associated with a running instance.'
        name = "address_#{address.id}_force_allocation"
        check_box_tag name, 1, address.force_allocation?, :title => title,
            :onclick => remote_function(
                :url => resource_bundle_server_address_url(resource_bundle, address),
                :with => "'server_resource[force_allocation]='+( $('#{name}').checked == true ? 1 : 0 )",
                :method => :put
            )
    end

    def remove_server_volume_link(text, resource_bundle, volume)
        url = resource_bundle_server_volume_url(resource_bundle, volume)
        options = {
            :url => url,
            :method => :delete,
            :confirm => "You sure you want to remove this volume from this launch configuration?\n\nThis action cannot be undone.",
        }
        html_options = {
            :title => "Remove volume from this launch configuration",
            :href => url,
            :method => :delete,
        }
        link_to_remote text, options, html_options
    end

    def server_volume_force_allocation_check_box(resource_bundle, volume)
        title = 'If checked, this volume will be moved to a new instance even if it is already associated with a running instance.'
        name = "volume_#{volume.id}_force_allocation"
        check_box_tag name, 1, volume.force_allocation?, :title => title,
            :onclick => remote_function(
                :url => resource_bundle_server_volume_url(resource_bundle, volume),
                :with => "'server_resource[force_allocation]='+( $('#{name}').checked == true ? 1 : 0 )",
                :method => :put
            )
    end
end
