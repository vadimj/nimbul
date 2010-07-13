module VolumesHelper
    def add_volume_link(name)
        link_to_function name do |page|
            page.insert_html :top, :volume_records, :partial => "volumes/volume", :object => @provider_account.volumes.build
        end
    end

	def volumes_sort_link(text, param)
		sort_link(text, param, nil, nil, :list)
	end
	
	def add_volume_link(text)
		url = new_provider_account_volume_path(@provider_account)
		link_text = image_tag("add.png", :class => 'control-icon', :alt => text)
		title = 'Allocate new Volume'
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

    def snapshot_volumes_submit(text)
        empty_selection_msg = "Please select volumes to snapshot."
        selectable_klass = "selectable_volume"
        html_options = {
            :name => 'snapshot',
            :alt => text,
            :class => 'control-icon',
            :title => "Snapshot Selected Volumes",
            :onclick => 'return (confirm_selection_not_empty("'+empty_selection_msg+'", "'+selectable_klass+'") && click_create_snapshot(this, "'+Time.now.to_s(:volume_snapshot_name)+'"));',  
        }
        image_submit_tag 'acquire.png', html_options
    end

    def delete_volumes_submit(text)
        empty_selection_msg = "Please select volumes to delete."
        confirm_msg = 'Are you sure?\n\nAll selected volumes will be deleted.\nThey will no longer be available under Server Profiles.'
        html_options = {
            :name => 'delete',
            :alt => text,
            :class => 'control-icon',
            :title => "Delete Selected Volumes",
            :onclick => "return confirm_multiple_action(this, '.command', 'destroy', '#{empty_selection_msg}', '#{confirm_msg}');",  
        }
        image_submit_tag 'trash.png', html_options
    end

end
