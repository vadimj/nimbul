module AutoScalingTriggersHelper
	def auto_scaling_triggers_sort_link(text, param)
		sort_link(text, param, :auto_scaling_triggers, nil, :list)
	end

    def add_auto_scaling_trigger_button(text, asg)
		link_text = text
		url = new_auto_scaling_group_trigger_url(asg)
    	options = {
            :url => url,
            :method => :get,
		}
		html_options = {
			:title => "Add Trigger to Group '#{asg.name}'",
            :href => url,
            :method => :get,
		}
		button_to_remote link_text, options, html_options
    end

	def activate_disable_auto_scaling_trigger_link(ast)
		if ast.parent_active?
			if ast.active?
				disable_auto_scaling_trigger_link(ast)
			else
				activate_auto_scaling_trigger_link(ast)
			end
		else
			image_tag 'status-disabled.png', {
				:class => 'control-icon-disabled',
				:alt => 'activate [disabled]',
				:title => 'To control the Trigger, activate its AS Group first',
			}
		end
	end

	def activate_auto_scaling_trigger_link(ast)
		link_text = image_tag 'status-active.png', {:class => 'control-icon', :alt => 'activate'}
		url = activate_auto_scaling_trigger_url(ast)
		options = {
			:url => url,
			:method => :post,
		}
		html_options = {
			:title => "Activate auto scaling trigger '#{ast.name}'",
			:href => url,
			:method => :post,
		}
		link_to_remote link_text, options, html_options
	end

	def disable_auto_scaling_trigger_link(ast)
		link_text = image_tag 'status-disabled.png', {:class => 'control-icon', :alt => 'disable'}
		url = disable_auto_scaling_trigger_url(ast)
		options = {
			:url => url,
			:method => :post,
		}
		html_options = {
			:title => "Disable auto scaling trigger '#{ast.name}'",
			:href => url,
			:method => :post,
		}
		link_to_remote link_text, options, html_options
	end

	def edit_auto_scaling_trigger_link(link_text, trigger)
		url = edit_auto_scaling_group_trigger_url(trigger.auto_scaling_group_id, trigger)
    	options = {
            :url => url,
            :method => :get,
		}
		html_options = {
			:title => "Edit Trigger '#{trigger.name}'",
            :href => url,
		}
		link_to_remote link_text, options, html_options
	end

	def edit_auto_scaling_trigger_image_link(trigger)
		edit_auto_scaling_trigger_link(
			image_tag(
				'verify.png', :class => 'control-icon',
				:alt => "Edit trigger '#{trigger.name}'",
				:title => "Edit trigger '#{trigger.name}'"
			), trigger
		)
	end

	def delete_auto_scaling_trigger_link(link_text, trigger)
		url = auto_scaling_trigger_url(trigger)
    	options = {
            :url => url,
            :method => :delete,
            :confirm => "Are you sure you want to delete trigger '#{trigger.name}'?"
		}
		html_options = {
			:title => "Delete Trigger '#{trigger.name}'",
            :href => url,
            :method => :delete,
		}
		link_to_remote link_text, options, html_options
	end

	def delete_auto_scaling_trigger_image_link(trigger)
		delete_auto_scaling_trigger_link(
			image_tag(
				'trash.png', :class => 'control-icon',
				:alt => "Delete trigger '#{trigger.name}'",
				:title => "Delete trigger '#{trigger.name}'"
			), trigger
		)
	end
end
