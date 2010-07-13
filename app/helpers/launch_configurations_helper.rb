module LaunchConfigurationsHelper
    def add_launch_configuration_link(name)
        link_to_function name do |page|
            page.insert_html :top, :launch_configuration_records, :partial => "launch_configurations/launch_configuration", :object => LaunchConfiguration.new
        end
    end

	def launch_configurations_sort_link(text, param)
		as_sort_link(text, param, :launch_configuration_data, 'launch_configuration_data')
	end
	
	def delete_launch_configuration_link(link_text, lc)
		url = launch_configuration_url(lc)
    	options = {
            :url => url,
            :method => :delete,
            :condition => "confirm_delete_launch_configuration('#{lc.name} ?')"
		}

		html_options = {
			:title => "Delete Launch Configuration '#{lc.name}'",
            :href => url,
            :method => :delete,
		}
		link_to_remote link_text, options, html_options
	end

	def delete_launch_configuration_image_link(lc)
		disabled = lc.locked?() ? ' [unable to delete while active]' : ''

		image_options = {
			:align => :absmiddle,
			:alt => "Delete Launch Configuration '#{lc.name}' #{disabled}",
			:title => "Delete Launch Configuration '#{lc.name}' #{disabled}"
		}
		
		image_optoins[:style] = 'opacity:0.35;filter:alpha(opacity=35);' if lc.locked?
		image = image_tag('trash.png', image_options)
		
		lc.unlocked? ? delete_launch_configuration_link(image, lc) : image
	end
	
	def activate_launch_configuration_link(link_text, lc)
		url = activate_launch_configuration_url(lc)
    	options = {
            :url => url,
            :method => :post,
		}

		html_options = {
			:title => "Activate Launch Configuration '#{lc.name}'",
            :href => url,
            :method => :post,
		}
		link_to_remote link_text, options, html_options
	end
	
	def activate_launch_configuration_image_link(lc)
		disabled = lc.locked?() ? ' [unable to change state while Active AS Groups are using this configuration]' : ''
		
		image_options = {
			:align => :absmiddle,
			:alt => "Activate Launch Configuration '#{lc.name}' #{disabled}",
			:title => "Activate Launch Configuration '#{lc.name}' #{disabled}"
		}
		
		image_optoins[:style] = 'opacity:0.35;filter:alpha(opacity=35);' if lc.locked?
		image = image_tag('status-active.png', image_options)
		
		lc.unlocked? ? activate_launch_configuration_link(image, lc) : image
	end

	def disable_launch_configuration_link(link_text, lc)
		url = disable_launch_configuration_url(lc)
    	options = {
            :url => url,
            :method => :post,
		}

		html_options = {
			:title => "Disable Launch Configuration '#{lc.name}'",
            :href => url,
            :method => :post,
		}
		link_to_remote link_text, options, html_options
	end
	
	def disable_launch_configuration_image_link(lc)
		disabled = lc.locked?() ? ' [unable to change state while Active AS Groups are using this configuration]'  : ''

		image_options = {
			:align => :absmiddle,
			:alt => "Disable Launch Configuration '#{lc.name}' #{disabled}",
			:title => "Disable Launch Configuration '#{lc.name}' #{disabled}"
		}
		
		image_options[:style] = 'opacity:0.35;filter:alpha(opacity=35);' if lc.locked?
		image = image_tag('status-disabled.png', image_options)
		
		lc.unlocked? ? disable_launch_configuration_link(image, lc) : image
	end
end
