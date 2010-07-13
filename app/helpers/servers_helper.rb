module ServersHelper
    def add_server_link(name)
        link_to_function name do |page|
            page.insert_html :top, :server_records, :partial => "servers/server", :object => @provider_account.servers.build
        end
    end

	# sorting helpers
	def servers_sort_link(text, param)
		sort_link(text, param, :servers, nil, :list)
	end

	def security_group_server_link(security_group, server)
		show_link = link_to security_group.name, security_group_servers_path(security_group), { :title => "Show all servers in group #{security_group.name}" }
        params.delete(:controller)
        params.delete(:action)
		options = {
            :url => security_group_server_url(security_group, server), :method => :delete,
		}
		html_options = {
			:title => "Remove this server from group #{security_group.name}",
            :href => security_group_server_url(security_group, server), :method => :delete,
		}
		remove_link = link_to_remote('X', options, html_options)

		'<div class="security_group_server">' + show_link + '&nbsp;|&nbsp;' + remove_link + '</div>'
	end

    def start_servers_submit(text, check_box_klass)
        empty_selection_msg = "Please select servers to power up."
        confirm_msg = ''
        html_options = {
            :name => 'delete',
            :alt => text,
            :class => 'control-icon',
            :title => "Launch Instances of selected Servers",
            :onclick => "return confirm_multiple_action(this, '.command', 'start', '#{empty_selection_msg}', '#{confirm_msg}', '', '', '#{check_box_klass}');",  
        }
        image_submit_tag 'start.png', html_options
    end
	
	def add_server_server_parameter_link(name)
        link_to_function name do |page|
            page.insert_html :bottom, :server_parameters, :partial => 'server_parameter', :object => ServerParameter.new
        end
    end

	def add_server_security_group_link(name)
        link_to_function name do |page|
            page.insert_html :bottom, :security_groups, :partial => 'security_group', :object => SecurityGroup.new
        end
    end

	def add_server_server_user_access_link(name)
        link_to_function name do |page|
            page.insert_html :bottom, :server_user_accesses, :partial => 'server_user_access', :object => ServerUserAccess.new({ :status_message => 'pending' })
        end
    end
	
	def remove_server_security_group_link(name, server, security_group)
		msg = "Are you sure you want to remove this group from the server?\n\n"
		msg += "Removing this group might prevent other instances from accessing new instances of this server.\n\n"
		msg += "NOTE: This change will not affect instances that are already running."
		url = server_security_group_url(server, security_group)
    	options = {
            :url => url,
            :method => :delete,
            :confirm => msg,
		}
		html_options = {
			:title => "Remove security group #{security_group.name}",
            :href => url,
            :method => :delete,
		}
		link_to_remote name, options, html_options
	end
	
	def show_hide_server_instances_link(server, show = 'show', hide = 'hide')
		expand_span_id = "expand_server_#{server.id}_instances"
		compress_span_id = "compress_server_#{server.id}_instances"
		instances_row_id = "server_#{server.id}_instances_row"
		
		html_options = {
			:class => 'bare-link',
		}

		link_text = "<small>" + server.instances.count.to_s + " total (#{show})</small>"
		options = {
			:url => server_instances_path(server),
			:method => :get,
			:success => "$('#{expand_span_id}').hide(); $('#{compress_span_id}').show(); $('#{instances_row_id}').show();",
		}
		show_link = link_to_remote link_text, options, html_options
		
		link_text = "<small>" + server.instances.count.to_s + " total (#{hide})</small>"
		js_function1 = "$('#{compress_span_id}').hide(); $('#{expand_span_id}').show(); $('#{instances_row_id}').innerHTML = '';"
		js_function = "$('#{compress_span_id}').hide(); $('#{expand_span_id}').show(); $('#{instances_row_id}').hide();"
		hide_link = link_to_function link_text, js_function, html_options
		
		result = content_tag(:span, show_link, { :id => expand_span_id })
		result += content_tag(:span, hide_link, { :id => compress_span_id, :style => 'display:none;' })
		return result
	end

	def select_server_with_auto_complete(model, field, options={})
		name = options[:name] || 'server_name'
		value = options[:value] || 'Server Missing'
		indicator = options[:indicator] || 'select_server_indicator'
		message_div = options[:message_div] || 'select_server_message'
		
		field_tag = hidden_field model, field
		
		js_tag = javascript_tag "
			function on#{name}Update(element, li) {
				alert(li.id);
			}
		"
		
		html_options = {
            :autocomplete => 'off',
            :class => 'auto_complete',
            :value => value,
            :onfocus => "if ($(this).value == '#{value}') { $(this).value = ''; }",
            :size => 50,
		}
		js_options = {
            :skip_style => true,
            :indicator => indicator,
            :min_chars => 3,
            :select => name,
            :after_update_element => "on#{name}Update",
		}
#            :with => "'server_search=' + encodeURIComponent($('#{name}').value)",
		search_field_tag = text_field_with_auto_complete model, name, html_options, js_options
		
		indicator_options = {
			:align => 'absmiddle',
            :border => 0,
            :id => indicator,
            :style => 'display: none;'
		}
		indicator_tag = image_tag 'indicator.gif', indicator_options
		
		field_tag + js_tag + search_field_tag + indicator_tag + "<div id='#{message_div}'></div>"
	end

    def server_description(server, search=nil)
        return '' if server.nil?
		provider_account = server.cluster.provider_account
		cluster = server.cluster
		name = h(server.name)
		name = highlight(name, search) if search
		
		#full_name = ''
		#full_name << h(provider_account.name)
		#full_name << ' / '+h(cluster.name)
		#full_name << ' / '+name
		#full_name << " [#{server.id}]"

		full_name = server.service_lineage_text
		
		content_tag :span, full_name, :class => 'server_name'
    end
    
    def dynamic_select_server(model, field, servers, clusters, provider_accounts)
		pa_select = collection_select model, :provider_account_id, provider_accounts, :id, :name, { :include_blank => 'choose account' }
		cluster_select = collection_select model, :cluster_id, clusters, :id, :name, { :include_blank => 'choose cluster' }
		server_select = collection_select model, field, servers, :id, :name, { :include_blank => 'choose server' }
		js_tag = render :partial => 'servers/dynamic_servers', :locals => { :model => model }
		pa_select + cluster_select + server_select + js_tag
    end
end
