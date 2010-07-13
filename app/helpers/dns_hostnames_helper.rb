module DnsHostnamesHelper
    def add_dns_hostname_link(name)
        link_to_function name do |page|
            page.insert_html :top, :dns_hostname_records, :partial => "hostname", :object => @provider_account.dns_hostnames.build
        end
    end

	# sorting helpers
	def dns_hostname_sort_link(text, param)
		sort_link(text, param, :dns_hostname_data, nil, :list)
	end

    def dns_hostname_description(hostname, search = nil)
        return '' if hostname.nil?
        result = ''
        result << (''+ h(hostname.name)) unless hostname.name.blank?
        result.gsub!(search, '<strong class="highlight">' + search + '</strong>') unless search.blank?
        result << ( ' <span class="dns_hostname_id" style="display: none;">' + hostname.id.to_s + '</span>' )
        return result
    end

	def delete_dns_hostname_link(link_text, model, hostname)
		url = polymorphic_url([model, hostname])
    	options = {
            :url => url,
            :method => :delete,
		}
		html_options = {
			:title => "Delete Hostname '#{hostname.name}'",
            :href => url,
            :method => :delete,
		}
		link_to_function link_text, "if (confirm_delete_hostname('#{hostname.name}')) { #{remote_function options } } else { return false; }", html_options
	end

	def delete_dns_hostname_image_link(model, hostname)
		delete_dns_hostname_link(
			image_tag(
				'trash_16x16.png', :align => 'absmiddle', :alt => "Delete Hostname", :width => 16, :height => 16
			), model, hostname
		)
	end

	def polymorphic_foreign_key_name(foreign_model)
		foreign_model.class.table_name.gsub!(/s$/,'') + '_' + foreign_model.class.primary_key
	end

	def reload_leases_javascript(hostname, delay = 3)
		"reload_leases({
			hostname_id: '#{hostname.id}',
			auth_token: '#{form_authenticity_token}',
			delay: '#{delay.to_f}'
		})"
	end

	def reload_hostname_javascript(hostname, delay = 3)
		"reload_hostname_leases({
			hostname_id: '#{hostname.id}',
			auth_token: '#{form_authenticity_token}',
			delay: '#{delay.to_f}'
		})"
	end

	def acquire_hostname_leases_link(link_text, model, hostname)
		url = polymorphic_url([:acquire, model, hostname])
		options = { :url => url, :method => :post, :success => reload_hostname_javascript(hostname) }
		html_options = {
			:title => "Acquire leases for all instances with assigned hostname '#{hostname.name}' for #{model.class.name} '#{model.name}' without a current lease.",
			:href => url,
			:method => :post,
		}
		link_to_remote link_text, options, html_options
	end

	def acquire_hostname_leases_image_link(server, hostname)
		acquire_hostname_leases_link(
			image_tag(
				'acquire.png', :align => 'absmiddle', :alt => 'acquire', :width => 16, :height => 16
			), server, hostname
		)
	end

	def release_lease_link(link_text, lease)
		url = release_dns_lease_url(lease)
		options = { :url => url, :method => :delete, :success => reload_hostname_javascript(lease.dns_hostname) }
		html_options = {
			:title => "Release lease '#{lease.fqdn}' from instance #{lease.instance_id}",
			:href => url,
			:method => :delete,
		}
		link_to_remote link_text, options, html_options
	end

	def release_leases_link(link_text, model, hostname = nil)
		polymorphic_args = [ :release, model ] + (hostname.nil? ? [ :dns_leases ] : [ hostname, :dns_leases] )
		url = polymorphic_url(polymorphic_args)
    	options = {
            :url => url,
            :method => :delete,
            :success => reload_hostname_javascript(hostname)
		}

    	title = if not hostname.nil?
			"Release ALL leases for '#{hostname.name}' assigned to #{model.class.name} '#{model.name}' instances."
		else
			"Release All leases for #{model.class.name} '#{model.name}' instances."
		end

		html_options = {
			:title => title,
            :href => url,
            :method => :delete,
		}
		link_to_remote link_text, options, html_options
	end

	def release_leases_image_link(model, hostname = nil)
		release_leases_link(
			image_tag(
				'release.png', :align => 'absmiddle', :alt => "Release All", :width => 16, :height => 16
			), model, hostname
		)
	end
	def unassign_server_hostname_link(link_text, server, hostname)
		url = unassign_server_dns_hostname_url(server, hostname)
    	options = {
            :url => url,
            :confirm => "Are you sure?\n\nPerforming this action will remove the '#{hostname.name}' hostname \nassignment from server (#{server.name})!",
            :method => :delete,
		}
		html_options = {
			:title => "Unassign Hostname '#{hostname.name}' from Server '#{server.name}'",
            :href => url,
            :method => :delete,
		}
		link_to_remote link_text, options, html_options
	end

	def unassign_server_hostname_image_link(server, hostname)
		unassign_server_hostname_link(
			image_tag(
				'detach.png', :align => 'absmiddle', :alt => "Release All",
				:width => 16, :height => 16
			), server, hostname
		)
	end

	def compress_leases_link(link_text, hostname)
		link_to_function(
			link_text,
			"
				$('hostname_#{hostname.id}_compress_leases').hide();
				$('hostname_#{hostname.id}_expand_leases').show();
				$('hostname_#{hostname.id}_leases').innerHTML = '';
			"
		)
	end

	def compress_leases_image_link(hostname)
		compress_leases_link(
			image_tag(
				'contract.png', :align => 'absmiddle', :alt => 'contract',
				:title => "Collapse list of leases #{hostname.name}",
				:width => 16, :height => 16
			), hostname
		)
	end

	def expand_leases_link(link_text, model, hostname)
		url = polymorphic_url([model, hostname, :dns_leases])
    	options = {
            :url => url,
            :method => :get,
            :success => "$('hostname_#{hostname.id}_expand_leases').hide(); $('hostname_#{hostname.id}_compress_leases').show();$('loading').hide();",
		}
		html_options = {
			:title => "Expand list of leases for '#{hostname.name}'",
            :href => url,
            :method => :get,
		}
		link_to_remote link_text, options, html_options
	end

	def expand_leases_image_link(model, hostname)
		expand_leases_link(
			image_tag(
				'expand.png', :align => 'absmiddle', :alt => 'expand', :width => 16, :height => 16
			),
			model, hostname
		)
	end

	def refresh_leases_link (link_text, hostname)
		html_options = {
			:title => "Refresh hostname and leases for '#{hostname.name}'",
		}
		link_to_function link_text, reload_hostname_javascript(hostname, 0), html_options
	end

	def refresh_leases_image_link(hostname)
		refresh_leases_link(
			image_tag(
				'refresh.png', :align => 'absmiddle', :alt => 'refresh lease list',
				:title => "Refresh list of leases for #{hostname.name}",
				:width => 16, :height => 16
			), hostname
		)
	end

	def hostname_instances_total(model, hostname)
		case model
		when Server:
			model.instances.select { |i| i.dns_assignable? }.size
		when Cluster:
			model.servers.select { |s| s.dns_hostnames.include? hostname }.inject(0) { |n,s| n = n + s.instances.select { |i| i.dns_assignable? }.size; n }
		when ProviderAccount:
			model.clusters.inject(0) do |n,c|
				n = n + c.servers.select { |s| s.dns_hostnames.include? hostname }.inject(0) { |x,s| x = x + s.instances.select { |i| i.dns_assignable? }.size; }; n
			end
		end
	end
end
