module TasksHelper
	def remove_task_link(text, task)
		link_text = image_tag('trash.png', :class => 'control-icon', :alt => text)
		if current_user.has_task_access?(task)
			url = task_url(task)
	    	options = {
	            :url => url,
	            :method => :delete,
	            :condition => "confirm('Are you sure you want to delete this task?')",
			}
			html_options = {
				:title => "Delete Task '#{task.name}'",
	            :href => url,
	            :method => :delete,
			}
			link_to_remote link_text, options, html_options
		end
	end

    def run_task_link(text, task)
		link_text = image_tag('start.png', :class => 'control-icon', :alt => text)
        url = run_task_url(task)

        options = {
			:url => url,
			:method => :get,
		}
        if not (message = task.get_operation.task_verify_message).empty?
			options[:condition] = "confirm_task_run('#{message}')"
        end
        
        html_options = {
            :title => 'Run Now',
            :href => url,
            :method => :get,
        }
        link_to_remote link_text, options, html_options
    end
end
