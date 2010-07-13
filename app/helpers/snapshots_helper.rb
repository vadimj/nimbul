module SnapshotsHelper
    def add_snapshot_link(name)
        link_to_function name do |page|
            page.insert_html :top, :snapshot_records, :partial => "snapshots/snapshot", :object => Snapshot.new
        end
    end

	def snapshots_sort_link(text, param)
		sort_link(text, param, nil, nil, :list)
	end

    def delete_snapshots_submit(text)
        empty_selection_msg = "Please select snapshots to delete."
        confirm_msg = 'Are you sure?\n\nAll selected snapshots will be deleted.\nThis cannot be undone.'
        html_options = {
            :name => 'delete',
            :alt => text,
            :class => 'control-icon',
            :title => "Delete Selected Snapshots",
            :onclick => "return confirm_multiple_action(this, '.command', 'destroy', '#{empty_selection_msg}', '#{confirm_msg}');",  
        }
        image_submit_tag 'trash.png', html_options
    end

    def restore_snapshots_submit(text, zones)
		options = "<option value=''>&lt;choose&gt;</option>"+zones.collect{ |z| "<option value='#{z.id}'>#{z.name}</option>" }.join('')
		select_zone_tag = select_tag(:zone_id, options, { :class => :zone })

		empty_selection_msg = "Please select snapshots to restore."
        selectable_klass = "selectable_snapshot"
        html_options = {
            :name => "restore",
            :alt => text,
            :class => "control-icon",
            :title => "Restore selected snapshots in selected zone",
            :onclick => "return (confirm_selection_not_empty('"+empty_selection_msg+"', '"+selectable_klass+"') && click_create_volume(this, $(this).previous('.zone'), 'Copy of'));",
        }
        restore_tag = image_submit_tag 'acquire.png', html_options

		select_zone_tag + restore_tag
    end
end
