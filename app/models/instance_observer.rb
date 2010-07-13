require 'fileutils'

class InstanceObserver < ActiveRecord::Observer
	@state_changed = false
	@dns_active_changed = false
	@ready_changed = false

	def before_save(instance)
		@state_changed = true if instance.state_changed?
		@dns_active_changed = true if instance.dns_active_changed?
		@ready_changed = true if instance.is_ready_changed?
		return true
	end

	def after_create(instance)
		# get launch configuration from the server (if available)
		unless instance.server_id.blank? or !instance.server.has_resource_bundles?
			begin
				server = instance.server
				# default prefix for messages
				msg_prefix = "instance.after_create: server #{server.name} [#{server.id}], instance #{instance.name} [#{instance.id}]"
				unless instance.pending_launch_configuration_id.blank?
					rb = server.resource_bundles.detect{ |rb| rb.id == instance.pending_launch_configuration_id }
				end
				# if not specified - find available in the instance's zone
				if rb.nil?
					rb = server.next_available_resource_bundle(instance.zone)
				end
				# configure resources if any
				unless rb.nil?
					rb.allocate!(instance)
					msg = "#{msg_prefix} - successfully allocated launch configuration [#{rb.id}]"
					Rails.logger.debug msg
				end
			rescue Exception => e
				msg = "#{msg_prefix} - failed to allocate launch configuration due to: #{e.message}"
				Rails.logger.error msg+"\n\t#{e.backtrace.join("\n\t")}"
				instance.errors.add(:state, msg)
				server.errors.add(:state, msg)
			end
		end
		
		return true		
	end

	def after_save(instance)
		# acquire / release dns leases
		if instance.is_ready?
			instance.acquire_dns_leases if (@ready_changed || @dns_active_changed) && instance.dns_assignable?
			if (@state_changed && instance.terminating?) || (@dns_active_changed && instance.dns_inactive?)
				instance.release_dns_leases
			end
		end
		# release resources
		if @state_changed and instance.terminating? and !instance.resource_bundle.nil?
			instance.resource_bundle.release!
		end
		return true
	end
end
