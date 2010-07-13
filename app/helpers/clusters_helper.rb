module ClustersHelper
    def add_cluster_link(name)
        link_to_function name do |page|
            page.insert_html :top, :cluster_records, :partial => 'cluster', :object => Cluster.new
        end
    end

	# sorting helpers
	def clusters_sort_link(text, param)
		sort_link(text, param, :clusters, nil, :list)
	end

	def add_cluster_user_link(name)
        link_to_function name do |page|
            page.insert_html :bottom, :users, :partial => 'user', :object => User.new
        end
	end

	def remove_cluster_link(text, cluster)
		if current_user.has_provider_account_access?(cluster.provider_account_id)
			link_text = image_tag("trash.png", :class => 'control-icon', :alt => text)
			url = cluster_url(cluster)
	    	options = {
	            :url => url,
	            :method => :delete,
	            :condition => "confirm_delete_cluster()",
			}
			html_options = {
				:title => "Delete cluster '#{cluster.name}'",
	            :href => url,
	            :method => :delete,
			}
			link_to_remote link_text, options, html_options
		end
	end

	def remove_cluster_user_link(name, cluster, user)
		url = cluster_user_url(cluster, user)
    	options = {
            :url => url,
            :method => :delete,
		}
		html_options = {
			:title => "Revoke access from #{user.login}",
            :href => url,
            :method => :delete,
		}
		link_to_remote name, options, html_options
	end

	def remove_cluster_server_link(text, cluster, server)
		url = cluster_server_url(cluster, server)
		link_text = image_tag("trash.png", :class => 'control-icon', :alt => text)
    	options = {
            :url => url,
            :confirm => "Are you sure?\n\nAll metadata associated with this Server will be deleted.",
            :method => :delete,
		}
		html_options = {
			:title => "Delete server '#{server.name}'",
            :href => url,
            :method => :delete,
		}
		link_to_remote link_text, options, html_options
	end
	
	def select_cloud_resource_cluster(form, cloud_resource, options = {})
		name = options[:name] || 'cluster_id'
		value = options[:value] || 'Choose a Cluster'
		indicator = options[:indicator] || 'select_cluster_indicator'
		message_div = options[:message_div] || 'select_cluster_message'
		
		html_options = {
            :autocomplete => 'off',
            :class => 'auto_complete',
            :value => value,
            :onfocus => "if ($(this).value == '#{value}') { $(this).value = ''; }"
		}
		js_options = {
            :skip_style => true,
            :indicator => indicator,
            :min_chars => 0,
            :select => name,
            :after_update_element => "function(element,value) { element.hide(); element.form.onsubmit(); element.value = ''; element.appear(); }",
            :with => "'cluster_search=' + encodeURIComponent($('#{name}').value) +'&cloud_resource_id=' + encodeURIComponent('#{@cloud_resource.id}')",
		}
		text_field_tag = text_field_with_auto_complete :cluster, :id, html_options, js_options
		
		indicator_options = {
			:align => 'absmiddle',
            :border => 0,
            :id => indicator,
            :style => 'display: none;'
		}
		indicator_tag = image_tag 'indicator.gif', indicator_options
		
		text_field_tag + indicator_tag + "<div id='#{message_div}'></div>"
	end
	
	def cluster_description(cluster, search = nil)
        return '' if cluster.nil?
        result = ''
        result << ('' + h(cluster.name) + '') unless cluster.name.blank?
        result.gsub!(search, '<strong class="highlight">' + search + '</strong>') unless search.blank?
        result << ( ' <snap class="cluster_id" style="display: none;">' + cluster.id.to_s + '</snap>' )
        return result
	end
end
