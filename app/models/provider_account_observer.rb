require 'transient_key_store'

class ProviderAccountObserver < ActiveRecord::Observer
  @messaging_password_changed = false
  
	def after_destroy account
		TransientKeyStore.instance(ENV['RAILS_ENV']).delete(account.aws_access_key_attribute)
		TransientKeyStore.instance(ENV['RAILS_ENV']).delete(account.aws_secret_key_attribute)
		TransientKeyStore.instance(ENV['RAILS_ENV']).delete(account.ssh_master_key_attribute)
		
		# remove the messaging user as part of removing the account
		account.send_control_update :del_node_account, :username => account.messaging_username
		true
	end

  def before_create account
    account.regenerate_messaging_password
  end
  
  def after_create account
    Rails.logger.info "Account created - sending control update"
    account.send_control_update :add_node_account    
  end
  
  def before_update account
    @messaging_password_changed = !!account.messaging_password_changed?
  end
  
  def after_update account
    unless not @messaging_password_changed
      Rails.logger.info "Sending Password Update for Messaging User '#{account.messaging_username}'"
      account.send_control_update :change_password    
    end
  end
end
