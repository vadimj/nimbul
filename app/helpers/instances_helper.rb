module InstancesHelper
	def instances_sort_link(text, param)
		sort_link(text, param, nil, nil, :list)
	end

    def reboot_instance_image_submit(text, check_box_klass)
        empty_selection_msg = "Please select instances to reboot."
        confirm_msg = 'Are you sure you want to reboot these instances?\n\nIt can take up to 5 minutes to reboot an Instance.'
        html_options = {
            :name => 'reboot',
            :alt => text,
            :class => 'control-icon',
            :title => "Reboot selected instances",
            :onclick => "return confirm_multiple_action(this, '.instance_command', 'reboot', '#{empty_selection_msg}', '#{confirm_msg}', '', '', '#{check_box_klass}');", 
        }
        image_submit_tag 'reboot.png', html_options
    end

    def terminate_instance_image_submit(text, check_box_klass)
        empty_selection_msg = "Please select instances to terminate."
        confirm_msg = 'Are you sure you want to terminate these instances?\n\nAll non-persistent data on this instance(s) will be lost.'
        html_options = {
            :name => 'terminate',
            :alt => text,
            :class => 'control-icon',
            :title => "Terminate selected instances",
            :onclick => "return confirm_multiple_action(this, '.instance_command', 'terminate', '#{empty_selection_msg}', '#{confirm_msg}', '', '', '#{check_box_klass}');", 
        }
        image_submit_tag 'stop.png', html_options
    end
    
    def reboot_instance_link(text, instance)
		title = "Reboot the instance"
		if instance.running?
			link_text = image_tag("reboot.png", :class => 'control-icon', :alt => text)
			if instance.is_locked?
				link_to_function link_text, 'alert("The instance is Locked.\n\nUnlock to reboot.");', :title => title
			else
				url = reboot_instance_url(instance)
				confirm_msg = "Are you sure?\n\nIt can take up to 5 minutes to reboot an instance."
				options = {
					:url => url,
					:confirm => confirm_msg,
					:method => :put,
				}
				html_options = {
				    :title => title,
				    :href => url,
				    :method => :put,
				}
				link_to_remote link_text, options, html_options
			end
		else
			image_tag("reboot.png",
				:class => 'control-icon-disabled',
				:alt => text+" [disabled]",
				:title => title+" [disabled]"
			) 
		end
    end
    
    def terminate_instance_link(text, instance)
		title = "Terminate the instance"
		if instance.running? or instance.rebooting? or instance.requested?
			link_text = image_tag("stop.png", :class => 'control-icon', :alt => text)
			if instance.is_locked?
				link_to_function link_text, 'alert("The instance is Locked.\n\nUnlock to terminate.");', :title => title
			else
				url = terminate_instance_url(instance)
				confirm_msg = "Are you sure?\n\nAll non-persistent data on this Instance will be lost."
				options = {
					:url => url,
					:confirm => confirm_msg,
					:method => :post,
				}
				html_options = {
				    :title => title,
				    :href => url,
				    :method => :post,
				}
				link_to_remote link_text, options, html_options
			end
		else
			image_tag("stop.png",
				:class => 'control-icon-disabled',
				:alt => text+" [disabled]",
				:title => title+" [disabled]"
			) 
		end
    end

    def instance_console_link(text, instance)
		text = image_tag("console.png", :class => 'small-icon', :alt => text)
		html_options = {
			:popup => [ "show_instance_console_output_#{instance.id}", 'height=660,width=860' ],
			:title => "Show Console Output"
		}
        link_to text, show_instance_console_output_path(instance), html_options            
    end

	def security_group_instance_link(security_group, instance)
		show_link = link_to security_group.name, security_group_instances_path(security_group), { :title => "Show all instances in group #{security_group.name}" }
		options = {
			:url => {
				:controller => 'instance/security_groups', :action => 'remove',
				:params => params.merge({ :security_group_id => security_group.id, :instance_id => instance.id })
			},
			:update => 'instances',
		}
		html_options = {
			:title => "Remove this instance from group #{security_group.name}",
			:href => url_for(
				:controller => 'instance/security_groups', :action => 'remove',
				:params => params.merge({ :security_group_id => security_group.id, :instance_id => instance.id })
			)
		}
		remove_link = link_to_remote('X', options, html_options)

#		'<div class="security_group_instance">' + show_link + '&nbsp;|&nbsp;' + remove_link + '</div>'
		'<div class="security_group_instance">' + show_link + '</div>'
	end
	
	def show_instances_with_status(instances, style='bullet')
		r = []
		terminated = instances.select{|i| i.terminating?}
		pending = instances.select{|i| i.pending? or i.requested?}
		running = instances.select{|i| i.running? and not i.is_ready?}
		ready = instances.select{|i| i.is_ready?}
		r << image_tag(style+'_red.png', :class => 'control-icon', :title => 'terminated')*terminated.length+" #{terminated.length}" unless terminated.empty?
		r << image_tag(style+'_yellow.png', :class => 'control-icon', :title => 'pending')*pending.length+" #{pending.length}" unless pending.empty?
		r << image_tag(style+'_green.png', :class => 'control-icon', :title => 'running')*running.length+" #{running.length}" unless running.empty?
		r << image_tag(style+'_blue.png', :class => 'control-icon', :title => 'ready')*ready.length+" #{ready.length}" unless ready.empty?
		r = r.join('<br/>')
		r = "<span class='small'>#{r}</span><br/>" unless r.blank?
	end
end
