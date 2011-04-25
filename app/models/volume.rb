
class Volume < BaseModel
	belongs_to :provider_account
    belongs_to :zone
	belongs_to :parent_snapshot, :class_name => 'Snapshot', :foreign_key => :snapshot_id
    has_many :snapshots, :primary_key => :volume_id, :foreign_key => :volume_id

	validates_presence_of :name, :zone_id
	validates_uniqueness_of :name, :scope => :provider_account_id
	validates_presence_of :snapshot_id, :if => :snapshot_id_and_size_are_blank, :message => 'Please specify size or snapshot'
	validates_presence_of :size, :if => :snapshot_id_and_size_are_blank, :message => 'Please specify size or snapshot'

    attr_accessor :should_destroy, :status_message, :destroyed, :size_or_snapshot
	after_destroy :mark_as_destroyed

	def snapshot_id_and_size_are_blank
        self.snapshot_id.blank? and self.size.blank?
	end

	def should_destroy?
        should_destroy.to_i == 1
    end

	def mark_as_destroyed
	    self.destroyed = true
	end

    def available?
        status == 'available'
    end

    def creating?
        status == 'creating'
    end

    def enable!
        update_attribute(:is_enabled, true)
    end

    def disable!
        update_attribute(:is_enabled, false)
    end

    def zone_and_name
        "#{zone} - #{name}"
    end

#    def self.search_by_cluster(cluster, search, page, extra_joins, extra_conditions, sort=nil, filter=nil)
#	    joins = [
#	  	    'INNER JOIN cloud_resources_clusters ON cloud_resources_clusters.cloud_resource_id = cloud_resources.id',
#	    ]
#	    joins = joins + extra_joins unless extra_joins.blank?
#
#        conditions = [ 'cloud_resources.type = ? AND cloud_resources_clusters.cluster_id = ?', self.to_s, (cluster.is_a?(Cluster) ? cluster.id : cluster) ]
#        conditions = [ 'cloud_resources.type = ? AND cloud_resources_clusters.cluster_id = ?', self.to_s, (cluster.is_a?(Cluster) ? cluster.id : cluster) ]
#	    unless extra_conditions.blank?
#		    extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
#		    conditions[0] << ' AND ' + extra_conditions[0];
#		    conditions << extra_conditions[1..-1]
#	    end
#		
#        self.search(search, page, joins, conditions, sort, filter)
#    end
  
    def self.search_by_provider_account(provider_account, search, page, extra_joins, extra_conditions, sort=nil, filter=nil)
	    joins = []
	    joins = joins + extra_joins unless extra_joins.blank?

#        conditions = [ 'cloud_resources.type = ? AND provider_account_id = ?', self.to_s, (provider_account.is_a?(ProviderAccount) ? provider_account.id : provider_account) ]
        conditions = [ 'provider_account_id = ?', (provider_account.is_a?(ProviderAccount) ? provider_account.id : provider_account) ]
	    unless extra_conditions.blank?
		    extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
		    conditions[0] << ' AND ' + extra_conditions[0];
		    conditions << extra_conditions[1..-1]
	    end
		
	    self.search(search, page, joins, conditions, sort, filter)
    end
  
    # sort, search and paginate parameters
    def self.per_page
        10
    end

    def self.sort_fields
        %w(name volume_id snapshot_id create_time size zone_id status instance_id is_enabled device)
    end

    def self.search_fields
        %w(name volume_id snapshot_id instance_id device)
    end
    
	def self.filter_fields
		%w(status owner_id)
	end

    def allocate!
        begin
            self.save
			size_or_snapshot = self.size.blank? ? self.snapshot_id : self.size
			res = Ec2Adapter.create_volume(self, size_or_snapshot, self.zone)
            self.update_attributes(res)
        rescue
            self.errors.add(:state, "#{$!}")
            self.status_message = "failed to allocate volume '#{self.name}': #{$!}"
            self.destroy
            return false
        end
        return true
	end

    def snapshot!(suffix = '')
        begin
            snapshot = Ec2Adapter.create_snapshot(self, suffix)
            self.status_message = "creating snapshot '#{snapshot.name}'"
            self.save
        rescue
            self.errors.add(:state, "#{$!}")
            self.status_message = "failed to snapshot volume '#{self.name}': #{$!}"
            return nil
        end
        return snapshot
	end

    def delete!
		# make sure it's not being used
		#unless self.server_resources.empty?
		#	self.errors.add(:state, "is being used by some servers")
		#	return false
		#end
		#unless self.instance_resources.empty?
		#	self.errors.add(:state, "is being used by some instances")
		#	return false
		#end
		
		# delete
        begin
            Ec2Adapter.delete_volume(self)
            self.status = 'deleting'
            self.status_message = 'delete requested'
		rescue
            self.errors.add(:state, "#{$!}")
            self.status_message = "failed to delete volume '#{self.name}': #{$!}"
            return false
        end
        
        return true
    end

end
