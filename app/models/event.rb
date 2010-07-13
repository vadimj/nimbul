
class Event < BaseModel

	belongs_to :provider_account
	belongs_to :security_group
	belongs_to :server
	belongs_to :user

	# sort parameters
	def self.per_page
        50
    end

    def self.sort_fields
        %w(provider_account_name security_group_name server_name user_login subject action object description created_at)
    end

    def self.search_fields
        %w(provider_account_name security_group_name server_name user_login subject action object description)
    end

	def self.log(options = {})
		Event.new(options).save
	end
end
