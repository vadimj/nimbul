class RemoveClusterHostFileUrlVariable < ActiveRecord::Migration
	def self.up
		# remove all the host_file_url variables from the clusters so new instances get the
		# new provider account level variable of the same name
		Publisher.find_all_by_type('Publishers::Ldns').each do |p|
			p.provider_account.clusters.each do |c|
				param = c.cluster_parameters.detect { |param| param.name == Publishers::Ldns::URL_PARAM_NAME }
				param.destroy unless param.nil?
			end
		end
	end
	
	def self.down
		# nothing - the cluster parameters will be recreated by the publisher if we are reverted 
	end
end
