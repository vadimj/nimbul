module AutoScalingGroupsHelper
	ApplicationHelper.setup_methods_for_subordinate 'auto_scaling_group', :instances, 'computer', nil, nil, 'index'
	ApplicationHelper.setup_methods_for_subordinate 'auto_scaling_group', :triggers, 'gauge-green'

	def auto_scaling_groups_sort_link(text, param)
		as_sort_link(text, param, :auto_scaling_group_data, 'auto_scaling_group_data')
	end

    def add_auto_scaling_group_link(name)
        link_to_function name do |page|
            page.insert_html :top, :auto_scaling_group_records, :partial => "auto_scaling_groups/auto_scaling_group", :object => LaunchConfiguration.new
        end
    end

	def delete_auto_scaling_group_link(link_text, asg_group)
		url = auto_scaling_group_url(asg_group)
    	options = {
            :url => url,
            :method => :delete,
            :condition => "confirm_delete_auto_scaling_group('#{asg_group.name}')"
		}

		html_options = {
			:title => "Delete Auto Scaling Group '#{asg_group.name}'",
            :href => url,
            :method => :delete,
		}
		link_to_remote link_text, options, html_options
	end

	def delete_auto_scaling_group_image_link(group)
		if group.disabled?
			link_text = image_tag 'trash.png', { :class => 'control-icon', :alt => "Delete Auto Scaling Group"}
			delete_auto_scaling_group_link link_text, group
		else
		    image_tag 'trash.png', :class => 'control-icon-disabled',
				:title => 'Delete Auto Scaling Group [disabled]',
				:alt => "Delete AutoScaling Group [disabled]"
		end
	end

	def enable_disable_auto_scaling_group_image_link(asg)
		if asg.active?
			disable_auto_scaling_group_image_link(asg)
		elsif asg.disabling?
			options = {}
			options[:class] = 'control-icon-disabled'
			options[:title] = 'Activate AutoScaling Group [disabled]'
			options[:alt] = options[:title]
			image_tag 'status-active.png', options
		else
			activate_auto_scaling_group_image_link(asg)
		end
	end

	def activate_auto_scaling_group_link(link_text, asg)
		url = activate_auto_scaling_group_url(asg)
		options = {
			:url => url,
			:method => :post,
		}

		size = [asg.min_size, asg.desired_capacity].max
		if size > 0
			confirm_msg = 'WARNING\n\nActivating this Group will start ' + size.to_s + ' instance'
			confirm_msg += 's' if size > 1
			confirm_msg += '\n'
			confirm_msg += 'Are you sure you want to proceed?'
			options[:condition] = "confirm('#{confirm_msg}')"
		end

		html_options = {
			:title => "Activate Auto Scaling Group '#{asg.name}'",
			:href => url,
			:method => :post,
		}
		link_to_remote link_text, options, html_options
	end
	
	def activate_auto_scaling_group_image_link(asg)
		activate_auto_scaling_group_link(
			image_tag(
				'status-active.png', :class => 'control-icon',
				:alt => "Activate Auto Scaling Group '#{asg.name}'",
				:title => "Activate Auto Scaling Group '#{asg.name}'"
			), asg
		)
	end

	def disable_auto_scaling_group_link(link_text, asg)
		url = disable_auto_scaling_group_url(asg)
		confirm_msg = 'WARNING\n\n'
		confirm_msg += 'Disabling this Auto Scaling Group will\n'
		confirm_msg += 'TERMINATE ALL Instances in this Group\n\n'
		confirm_msg += 'Are you sure you want to disable this Group?'
		prompt_msg = 'CONFIRMATION\n\nALL Instances in this Group will be TERMINATED\n\nType yes to proceed and disable the Group:'
		options = {
			:url => url,
			:method => :post,
			:condition => "confirm('#{confirm_msg}') && ('yes' == prompt('#{prompt_msg}'))",
		}

		html_options = {
			:title => "Disable Auto Scaling Group '#{asg.name}'",
			:href => url,
			:method => :post,
		}
		link_to_remote link_text, options, html_options
	end
	
	def disable_auto_scaling_group_image_link(asg)
		disable_auto_scaling_group_link(
			image_tag(
				'status-disabled.png', :class => 'control-icon',
				:alt => "Disable Auto Scaling Group '#{asg.name}'",
				:title => "Disable Auto Scaling Group '#{asg.name}'"
			), asg
		)
	end
	
	def auto_scaling_group_numeric_parameter(asg, par, options={})
		step = options[:step] || 1
		min_value = options[:min_value] || 0
		max_value = options[:max_value]
		unit = options[:unit]
		msg = options[:message]
		
		url = auto_scaling_group_url(asg)
		curr_val = asg.send(par)
		
		new_val = (curr_val > min_value) ? (curr_val-step) : 0
		new_val = (new_val > min_value) ? new_val : min_value
		if curr_val > min_value
			link_text = image_tag 'less.png', :class => 'control-icon'
			ajax_options = {
				:url => url,
				:method => :put,
				:with => "'auto_scaling_group[#{par.to_s}]=#{new_val}'",
			}
			html_options = {
				:title => "decrease to #{new_val}",
				:href => url,
				:method => :put,
			}
			less_link = link_to_remote link_text, ajax_options, html_options
		else
			less_link = image_tag 'less.png', :class => 'control-icon-disabled', :title => (msg || "already at #{min_value}")
		end

		if max_value.nil? or (curr_val < max_value)
			new_val = curr_val + step
			new_val = (max_value.nil? or new_val < max_value) ? new_val : max_value
			link_text = image_tag 'more.png', :class => 'control-icon'
			ajax_options = {
				:url => url,
				:method => :put,
				:with => "'auto_scaling_group[#{par.to_s}]=#{new_val}'",
			}
			html_options = {
				:title => "increase to #{new_val}",
				:href => url,
				:method => :put,
			}
			more_link = link_to_remote link_text, ajax_options, html_options
		else
			more_link = image_tag 'more.png', :class => 'control-icon-disabled', :title => (msg || "already at #{max_value}")
		end
		
		r = less_link
		r += curr_val.to_s
		r += ' '+unit unless unit.blank?
		r += more_link
		return r
	end
	
	def auto_scaling_group_min_size(asg)
		auto_scaling_group_numeric_parameter(asg, :min_size)
	end
	
	def auto_scaling_group_max_size(asg)
		auto_scaling_group_numeric_parameter(asg, :max_size)
	end
	
	def auto_scaling_group_desired_capacity(asg)
		options ={
			:min_value => asg.min_size,
			:max_value => asg.max_size,
			:message => "Desired Capacity must be between Minimum and Maximum Size (#{asg.min_size} and #{asg.max_size})"
		}
		auto_scaling_group_numeric_parameter(asg, :desired_capacity, options)
	end
	
	def auto_scaling_group_cooldown(asg)
		options = {
			:step => 30,
			:max_value => 86400,
			:unit => 'sec',
		}
		auto_scaling_group_numeric_parameter(asg, :cooldown, options)
	end
	
	def show_hide_auto_scaling_group_instances_link(asg)
		if asg.instances.size > 0
			r = content_tag(:span, expand_instances_image_link(asg), :id => "auto_scaling_group_#{asg.id}_expand_instances")
			r += content_tag(:span, hide_instances_image_link(asg), :id => "auto_scaling_group_#{asg.id}_compress_instances", :style => "display:none;")
			return r
		else
			options ={}
			options[:class] = 'control-icon-disabled'
			options[:title] = 'List Instances [none available]'
			options[:alt] = options[:title]
			image_tag 'computer.png', options
		end
	end

	def show_hide_auto_scaling_group_triggers_link(asg)
		r = content_tag(:span, expand_triggers_image_link(asg), :id => "auto_scaling_group_#{asg.id}_expand_triggers")
		r += content_tag(:span, hide_triggers_image_link(asg), :id => "auto_scaling_group_#{asg.id}_compress_triggers", :style => "display:none;")
		return r
	end
end
