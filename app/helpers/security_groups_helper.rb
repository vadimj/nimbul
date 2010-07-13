module SecurityGroupsHelper
    def add_security_group_link(name)
        link_to_function name do |page|
            page.insert_html :top, :security_group_records, :partial => "security_groups/security_group", :object => SecurityGroup.new
        end
    end

	# sorting helpers
	def security_groups_sort_link(text, param)
		sort_link(text, param, :security_groups, nil, :list)
	end

	def add_security_group_firewall_rule_link(name)
        link_to_function name do |page|
            page.insert_html :bottom, :firewall_rules, :partial => 'firewall_rule', :object => User.new
        end
	end
    
   def remove_security_group_firewall_rule_link(name, security_group, firewall_rule)
        url = security_group_firewall_rule_url(security_group, firewall_rule)
        confirm_msg = "Are you sure?\n\n"
        confirm_msg += "Removing a firewall rule might prevent other machines\n"
        confirm_msg += firewall_rule.description
        confirm_msg += "\n"
        confirm_msg += "from connecting to instances in this group."
        options = {
            :url => url,
            :method => :delete,
            :confirm => confirm_msg,
        }
        html_options = {
            :title => "Remove '#{firewall_rule.name}' firewall rule",
            :href => url,
            :method => :delete,
        }
        link_to_remote name, options, html_options
    end
   
    def destroy_security_group_link(text, security_group)
		options = {
			:url => provider_account_security_group_path(security_group.provider_account, security_group),
			:method => :delete,
			:confirm => "Are you sure?\n\nSecurity group "+security_group.name+" will deleted from your Account.\nThis action cannot be undone.",
		}
		link_to_remote text, options
    end
end
