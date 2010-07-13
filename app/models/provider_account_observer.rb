require 'transient_key_store'

class ProviderAccountObserver < ActiveRecord::Observer
	def after_destroy(account)
		TransientKeyStore.instance(ENV['RAILS_ENV']).delete(account.aws_access_key_attribute)
		TransientKeyStore.instance(ENV['RAILS_ENV']).delete(account.aws_secret_key_attribute)
		TransientKeyStore.instance(ENV['RAILS_ENV']).delete(account.ssh_master_key_attribute)
		true
	end
end
