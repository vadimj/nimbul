module FirewallRulesHelper
	# sorting helpers
	def firewall_rules_sort_link(text, param)
		sort_link(text, param, :firewall_rules, nil, :list)
	end

	def select_security_group_firewall_rule(form, security_group, options = {})
		name = options[:name] || 'firewall_rule_id'
		value = options[:value] || 'Add a Firewall Rule'
		indicator = options[:indicator] || 'select_firewall_rule_indicator'
		message_div = options[:message_div] || 'select_firewall_rule_message'
		
		html_options = {
            :autocomplete => 'off',
            :class => 'auto_complete',
            :value => value,
            :onfocus => "if ($(this).value == '#{value}') { $(this).value = ''; }"
		}
		js_options = {
            :skip_style => true,
            :indicator => indicator,
            :min_chars => 3,
            :select => name,
            :after_update_element => "function(element,value) { element.hide(); element.form.onsubmit(); element.value = ''; element.appear(); }",
            :with => "'firewall_rule_search=' + encodeURIComponent($('#{name}').value) +'&id=' + encodeURIComponent('#{@security_group.id}')",
		}
		text_field_tag = text_field_with_auto_complete :firewall_rule, :id, html_options, js_options
		
		indicator_options = {
			:align => 'absmiddle',
            :border => 0,
            :id => indicator,
            :style => 'display: none;'
		}
		indicator_tag = image_tag 'indicator.gif', indicator_options
		
		text_field_tag + indicator_tag + "<div id='#{message_div}'></div>"
	end

    def firewall_rule_description(firewall_rule, search = nil)
        return '' if firewall_rule.nil?
        result = ''
        result << ('' + h(firewall_rule.name) + ' (') unless firewall_rule.name.blank?
        result << h(firewall_rule.ip_range) unless firewall_rule.ip_range.blank?
        result << h(firewall_rule.group_name) unless firewall_rule.group_name.blank?
        result << ')'
        result.gsub!(search, '<strong class="highlight">' + search + '</strong>') unless search.blank?
        result << ( ' <snap class="firewall_rule_id" style="display: none;">' + firewall_rule.id.to_s + '</snap>' )
        return result
    end

    def add_firewall_rule_link(text)
        url = new_provider_account_firewall_rule_path(@provider_account)
        link_text = image_tag("add.png", :class => 'control-icon', :alt => text)
		options = {
			:url => url,
			:method => :get,
		}
		html_options = {
		    :href => url,
		    :method => :get,
		}
        link_to_remote link_text, options, html_options
    end

    def add_firewall_rule_button(text)
        html_options = {
            :class => 'control-icon',
            :alt => text,
            :title => 'Add a Firewall Rule',
        }
        link_text = image_tag 'add.png', html_options
        add_firewall_rule_link link_text
    end

    def remove_firewall_rule_submit(text)
        empty_selection_msg = "Please select rules to delete."
        confirm_msg = 'Are you sure?\n\nAll selected rules will be deleted.\nThis cannot be undone.'
        html_options = {
            :name => 'destroy',
            :alt => text,
            :class => 'control-icon',
            :title => "Deregister Selected Firewall Rules",
            :onclick => "return confirm_multiple_action(this, '.command', 'destroy', '#{empty_selection_msg}', '#{confirm_msg}');", 
        }
        image_submit_tag 'trash.png', html_options
    end

    def enable_firewall_rules_submit(text)
        empty_selection_msg = "Please select rules to enable."
        html_options = {
            :name => 'enable',
            :alt => text,
            :class => 'control-icon',
            :title => "Enable Selected Firewall Rules",
            :onclick => "return confirm_multiple_action(this, '.command', 'enable', '#{empty_selection_msg}');", 
        }
        image_submit_tag 'enable.png', html_options
    end

    def disable_firewall_rules_submit(text)
        empty_selection_msg = "Please select rules to disable."
        confirm_msg = 'Are you sure?\n\nAll selected rules will be hidden.\nThey will no longer be available under security groups.'
        html_options = {
            :name => 'disable',
            :alt => text,
            :class => 'control-icon',
            :title => "Disable Selected Firewall Rules",
            :onclick => "return confirm_multiple_action(this, '.command', 'disable', '#{empty_selection_msg}', '#{confirm_msg}');", 
        }
        image_submit_tag 'disable.png', html_options
    end

end
