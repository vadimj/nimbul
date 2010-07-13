require 'ldap_connect'

class LdapUser < User
	attr_accessor :password

	# ldap authentication, only available to LdapUsers
	# yield user, message, item_msg, item_path
	def self.authenticate(username, password, &block)
		if (username.blank? || password.blank?)
			yield nil,
				"Username and password cannot be blank.",
				nil,
				nil and return
		end
		user = find :first, :conditions => ['login = ?', username], :include => [:roles, :provider_accounts, :security_groups]
		unless ( user && LDAP.authenticate(username, password) )
			yield nil,
				"Could not log you in as '#{CGI.escapeHTML(username)}', your username or password is incorrect.",
				nil, 
				nil and return
		end
		case
			when !user.active?
				yield nil,
				"Your account has not been activated, please check your email or %s.",
				"request a new activation code",
				"resend_activation_path"
			when !user.enabled?
				yield nil,
				"Your account has been disabled, please %s.",
				"contact the administrator",
				"contact_site"
			else
				yield user,
				nil,
				nil,
				nil
		end
	end
end
