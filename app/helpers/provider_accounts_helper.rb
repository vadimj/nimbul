module ProviderAccountsHelper
    def add_provider_account_link(text)
        url = new_provider_account_path
        link_text = image_tag("add.png", :class => 'control-icon', :alt => text)
		title = 'Add an Account'
		html_options = {
            :title => title,
		}
        link_to link_text, url, html_options
    end

    def delete_provider_accounts_submit(text)
        empty_selection_msg = "Please select accounts to delete."
        confirm_msg = 'Are you sure?\n\n'
        confirm_msg += 'All metadata associated with selected accounts will be deleted.\n\n'
        confirm_msg += 'This includes all server, groups, firewall rules, storage and addresses metadata.\n\n'
        confirm_msg += 'This action cannot be undone.\n'
        double_confirm_message = 'Type yes to confirm that you want to delete selected Accounts.'
        html_options = {
            :name => 'enable',
            :alt => text,
            :class => 'control-icon',
            :title => "Delete selected accounts",
            :onclick => "return confirm_multiple_action(this, '.command', 'destroy', '#{empty_selection_msg}', '#{confirm_msg}', '#{double_confirm_message}');",  
        }
        image_submit_tag 'trash.png', html_options
    end

	def provider_accounts_sort_link(text, param)
		sort_link(text, param, :provider_accounts, nil, :list)
	end

	def add_provider_account_user_link(name)
        link_to_function name do |page|
            page.insert_html :bottom, :users, :partial => 'user', :object => User.new
        end
    end

    def add_provider_account_user_link(name, provider_account, user)
		url = provider_account_users_url(provider_account)
    	options = {
            :url => url,
            :with => "user_id='#{user.id}'",
            :method => :put,
		}
		html_options = {
			:title => "Revoke access from #{user.login}",
            :href => url,
            :with => "user_id='#{user.id}'",
            :method => :put,
		}
		link_to_remote name, options, html_options
    end

	def remove_provider_account_user_link(name, provider_account, user)
		url = provider_account_user_url(provider_account, user)
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
end	
