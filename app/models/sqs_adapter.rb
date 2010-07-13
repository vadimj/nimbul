require 'AWS/SQS'
require 'aws_context'
require 'pp'

class SqsAdapter
	def self.get_sqs(credentials)
		return nil if credentials.nil?
		if credentials.is_a? ProviderAccount
			return nil if credentials.aws_access_key.blank? or credentials.aws_secret_key.blank?
			keys = [ credentials.aws_access_key, credentials.aws_secret_key, true, true ]
		elsif credentials.is_a? Array
			keys = credentials 
		end
		AwsContext.setup(:aws)
		sqs = AwsContext.instance.sqs(*keys)
	end

	def self.create_queue(account, name, visibility_timeout_secs=0)
		sqs = get_sqs(account)
		# create the queue if it doesn't exist
		if sqs.list_queues(name).size == 0
			sqs.create_queue(name, visibility_timeout_secs)
		end
	end

	def self.add_account_permission(account, name, grantee_account_id, action)
		sqs = get_sqs(account)
		url = (name.match(/^http/) ? name : sqs.list_queues(name).first)
		sqs.add_account_permission(url, grantee_account_id, action)
	end

	def self.del_account_permission(account, name, grantee_account_id, action)
		sqs = get_sqs(account)
		url = (name.match(/^http/) ? name : sqs.list_queues(name).first)
		sqs.remove_account_permission(url, grantee_account_id, action)
	end

	def self.allow_receive(account, name, grantee_account_id)
		add_account_permission(account, name, grantee_account_id, 'ReceiveMessage')
	end

	def self.revoke_receive(account, name, revokee_account_id)
		del_account_permission(account, name, grantee_account_id, 'ReceiveMessage')
	end

	def self.allow_delete(account, name, grantee_account_id)
		add_account_permission(account, name, grantee_account_id, 'DeleteMessage')
	end

	def self.revoke_delete(account, name, revokee_account_id)
		del_account_permission(account, name, grantee_account_id, 'DeleteMessage')
	end

	def self.allow_send(account, name, grantee_account_id)
		add_account_permission(account, name, grantee_account_id, 'SendMessage')
	end

	def self.revoke_send(account, name, revokee_account_id)
		del_account_permission(account, name, grantee_account_id, 'SendMessage')
	end
	
	def self.allow_change_visibility(account, name, grantee_account_id)
		add_account_permission(account, name, grantee_account_id, 'ChangeMessageVisibility')
	end
	
	def self.revoke_change_visibility(account, name, grantee_account_id)
		del_account_permission(account, name, grantee_account_id, 'ChangeMessageVisibility')
	end
end
