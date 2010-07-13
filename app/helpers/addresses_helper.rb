module AddressesHelper
	def addresses_sort_link(text, param)
		sort_link(text, param, nil, nil, :list)
	end

    def allocate_address_link(text)
        url = new_provider_account_address_path(@provider_account)
        link_text = image_tag("add.png", :class => 'control-icon', :alt => text)
		title = 'Allocate an Address'
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

    def enable_addresses_submit(text)
        empty_selection_msg = "Please select addresses to enable."
        html_options = {
            :name => 'enable',
            :alt => text,
            :class => 'control-icon',
            :title => "Enable Selected Addresses",
            :onclick => "return confirm_multiple_action(this, '.command', 'enable', '#{empty_selection_msg}');", 
        }
        image_submit_tag 'enable.png', html_options
    end

    def disable_addresses_submit(text)
        empty_selection_msg = "Please select addresses to disable."
        confirm_msg = 'Are you sure?\n\nAll selected Addresses will be hidden.\nThey will no longer be available under Server Profiles.'
        html_options = {
            :name => 'disable',
            :alt => text,
            :class => 'control-icon',
            :title => "Disable Selected Addresses",
            :onclick => "return confirm_multiple_action(this, '.command', 'disable', '#{empty_selection_msg}', '#{confirm_msg}');", 
        }
        image_submit_tag 'disable.png', html_options
    end
    
    def release_addresses_submit(text)
        empty_selection_msg = "Please select addresses to release."
        confirm_msg = 'Are you sure?\n\nAll selected Addresses will be released back to the Cloud.\nThey will no longer be available under Server Profiles.'
        html_options = {
            :name => 'release',
            :alt => text,
            :class => 'control-icon',
            :title => "Release Selected Addresses",
            :onclick => "return confirm_multiple_action(this, '.command', 'release', '#{empty_selection_msg}', '#{confirm_msg}');",  
        }
        image_submit_tag 'trash.png', html_options
    end
end
