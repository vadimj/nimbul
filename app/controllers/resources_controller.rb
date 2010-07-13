class ResourcesController < ApplicationController
	def index
		@provider_accounts_count = ProviderAccount.count
        @security_groups_count = SecurityGroup.count
        @servers_count = Server.count
        # @instances_count = Instance.count
	end
end
