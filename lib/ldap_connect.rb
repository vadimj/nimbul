require 'net/ldap'

module LDAP
	def using_ldap?
		params[:using_ldap] == '1'
	end
  
	def self.authenticate(username, password)
		return false if (username.blank? || password.blank?)
		ldap = Net::LDAP.new(
    		:host => APP_CONFIG['ldap']['server'],
			:port => APP_CONFIG['ldap']['port'],
    		:base => APP_CONFIG['ldap']['base']
		)
		filter = Net::LDAP::Filter.eq('uid', username.chomp)
		ldap.search(:filter => filter) {|entry| username = entry.dn}
		ldap.auth(username, password)
		return true if ldap.bind
		return false
	end

	def self.get_attribute(username, attribute_name)
		return false if username.blank?
		ldap = Net::LDAP.new(
    		:host => APP_CONFIG['ldap']['server'],
			:port => APP_CONFIG['ldap']['port'],
    		:base => APP_CONFIG['ldap']['base']
		)

    	filter = Net::LDAP::Filter.eq('uid', username.chomp)
    	ldap.search(:filter => filter) do |entry|
			entry.each do |attribute, values|
				if attribute.to_s.chomp == attribute_name then
					values.each do |value|
						return value
					end
				end
			end
		end
	end

	def self.get_email(username)
		get_attribute(username, 'mail')
	end

	def self.get_name(username)
		get_attribute(username, 'cn')
	end
end
