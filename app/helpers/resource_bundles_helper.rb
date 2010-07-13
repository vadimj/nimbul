module ResourceBundlesHelper
    def add_resource_bundle_link(text, server)
        link_to_function text do |page|
            page[:add_resource_bundle].hide
            page[:new_resource_bundle].appear
        end
    end
    
    def cancel_add_resource_bundle_button(text, server)
        button_to_function text do |page|
            page[:new_resource_bundle].hide
            page[:add_resource_bundle].appear
        end
    end
    
   	def start_server_resource_bundle_link(text, server, resource_bundle)
		if resource_bundle.is_default? or resource_bundle.instance_id.blank?
			url = start_server_resource_bundle_url(resource_bundle.server, resource_bundle)
			link_text = image_tag("start.png", :class => 'control-icon', :alt => text)
			options = {
			    :url => url,
			    :method => :post,
			    :with => "'resource_bundle_id=#{resource_bundle.id}'",
			}
			html_options = {
				:title => "Start an instance of this server using this launch configuration",
			    :href => url,
			    :method => :post,
			    :with => "'resource_bundle_id=#{resource_bundle.id}'",
			}
			link_to_remote link_text, options, html_options
		else
			image_tag("start.png",
				:class => 'control-icon-disabled',
				:alt => text,
				:title => "Another instance uses this non-default configuration"
			) 
		end
	end

   	def remove_resource_bundle_link(text, server, resource_bundle)
		if resource_bundle.instance_id.blank?
			url = server_resource_bundle_url(server, resource_bundle)
			link_text = image_tag("trash.png", :class => 'control-icon', :alt => text)
	    	options = {
	            :url => url,
	            :method => :delete,
	            :confirm => "Are you sure you want to remove\nthis launch configuration?",
			}
			html_options = {
				:title => "Remove this bundle from server '#{server.name}'",
	            :href => url,
	            :method => :delete,
			}
			link_to_remote link_text, options, html_options
		else
			image_tag("trash.png",
				:class => 'control-icon-disabled',
				:alt => text,
				:title => "This launch configuration is currently in use and cannot be deleted."
			) 
		end
	end

   	def make_default_resource_bundle_link(text, server, resource_bundle)
		if resource_bundle.is_default?
			image_tag("acquire.png",
				:class => 'control-icon-disabled',
				:alt => text,
				:title => "This is default configuration"
			) 
		else
			url = make_default_server_resource_bundle_url(server, resource_bundle)
			link_text = image_tag("acquire.png", :class => 'control-icon', :alt => text)
			options = {
			    :url => url,
			    :method => :post,
			}
			html_options = {
				:title => "Make this configuration default configuration",
			    :href => url,
			    :method => :post,
			}
			link_to_remote link_text, options, html_options
		end
	end
end
