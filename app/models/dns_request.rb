
class DnsRequest < BaseModel
	belongs_to :instance
	belongs_to :dns_hostname_assignment
	
	validates_presence_of :instance_id, :dns_hostname_assignment_id
	validates_presence_of :request_type

	def self.process_requests
		(DnsRequest.find(:all) || []).sort!{ |a,b| a.id <=> b.id }.each { |request| request.run }
		true
	end
		
	def run 
		case request_type.to_sym
			when :acquire
				acquire
			when :release
				release
		end
	end
	
	private
	
	def acquire
		begin
			# if our instance has gone away, or is not yet ready, then concel the request
			instance = Instance.find(self.instance_id) rescue nil
			if not instance or not instance.running?
				self.destroy
				return false
			elsif instance.dns_inactive?
				return false
			end
			
			assignment = self.dns_hostname_assignment
			lease = DnsLease.find_available(assignment)

			if lease.nil?
				index =  DnsLease.find(
					:first,
					:select => 'max(idx) + 1 AS idx',
					:conditions => [ 'dns_hostname_assignment_id = ?', assignment.id ],
					:order => 'idx ASC'
				).idx || 0
				lease = assignment.dns_leases.create :idx => index
			end
			lease.update_attribute(:instance_id, self.instance_id)
		rescue Exception => e # just log it
			Rails.logger.error e.backtrace.join("\n")
			return false
		ensure
			# if it fails, remove the request. let the user manually re-request this operation (for now)
			# FIXME: better 'what to do' in the case of failure
			self.destroy
		end
		true
	end
	
	def release
		# if our instance has gone away, or is not yet ready, then concel the request
		instance = Instance.find(self.instance_id) rescue nil
		if not instance or (instance.pending? or instance.requested?)
			self.destroy
			return false
		end

		begin
			lease = DnsLease.find_by_instance_id_and_dns_hostname_assignment_id(self.instance_id, self.dns_hostname_assignment_id)
			lease.update_attribute(:instance_id, nil) unless lease.nil?
		rescue Exception => e # just log it
			Rails.logger.error e.backtrace.join("\n")
			return false
		ensure # if it fails, don't bother retrying it - just skip this request
			self.destroy
		end
		true
	end
end
