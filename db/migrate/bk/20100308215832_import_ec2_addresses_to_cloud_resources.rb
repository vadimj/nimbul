class ImportEc2AddressesToCloudResources < ActiveRecord::Migration
  def self.up
	Address.find(:all).each do |a|
	  pa = a.provider_account
	  ec2_address = pa.ec2_addresses.build({
		:cloud_id => a.public_ip,
		:name => a.name,
		:state => a.state,
		:is_enabled => a.is_enabled,
	  })
	  ec2_address.save
	end
	ProviderAccount.find(:all).each do |pa|
	  pa.clusters.each do |cluster|
		cluster.servers.each do |server|
		  unless server.public_ip.nil?
		    ec2_address = pa.ec2_addresses.detect{ |a| a.cloud_id == server.public_ip }
		    if ec2_address
			  scra = server.server_cloud_resource_allocations.build({
			    :cloud_resource_id => ec2_address.id,
			    :force_allocation => server.force_public_ip_allocation,
			  })
			  scra.save
			  cluster.cloud_resources << ec2_address unless cluster.cloud_resources.include?(ec2_address)
			end
		  end
		end
	  end
	  pa.instances.each do |instance|
		unless instance.public_ip.nil?
		  ec2_address = pa.ec2_addresses.detect{ |a| a.cloud_id == instance.public_ip }
		  if ec2_address
			icra = instance.instance_cloud_resource_allocations.build({
			  :cloud_resource_id => ec2_address.id,
			  :state => 'active',
			})
			icra.save
		  end
		end
		unless instance.pending_public_ip.nil?
		  ec2_address = pa.ec2_addresses.detect{ |a| a.cloud_id == instance.pending_public_ip }
		  if ec2_address
			icra = instance.instance_cloud_resource_allocations.build({
			  :cloud_resource_id => ec2_address.id,
			  :state => 'pending',
			  :force_allocation => instance.force_public_ip_allocation,
			})
			icra.save
		  end
		end
	  end
	end
  end

  def self.down
	InstanceCloudResourceAllocation.delete_all
	ServerCloudResourceAllocation.delete_all
	Ec2Address.delete_all
  end
end
