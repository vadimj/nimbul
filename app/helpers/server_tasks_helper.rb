module ServerTasksHelper
	def remove_server_task_link(text, server_task)
		link_text = image_tag('trash.png', :class => 'control-icon', :alt => text)
		if current_user.has_server_task_access?(server_task)
			url = server_server_task_url(server_task.server, server_task)
	    	options = {
	            :url => url,
	            :method => :delete,
	            :condition => "confirm('Are you sure you want to delete this task?')",
			}
			html_options = {
				:title => "Delete Task '#{server_task.name}'",
	            :href => url,
	            :method => :delete,
			}
			link_to_remote link_text, options, html_options
		end
	end

    def run_server_task_link(text, server_task)
		link_text = image_tag('start.png', :class => 'control-icon', :alt => text)
        url = run_server_server_task_url(server_task.server, server_task)

        options = {
			:url => url,
			:method => :get,
		}
        if not (message = server_task.get_operation.task_verify_message).empty?
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
