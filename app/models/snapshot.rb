require 'aasm'

class Snapshot < BaseModel
    include AASM
	belongs_to :provider_account
	belongs_to :parent_volume, :class_name => 'Volume', :foreign_key => :volume_id
	has_many :volumes, :primary_key => :snapshot_id, :foreign_key => :snapshot_id

    # aasm
    aasm_column :status
    aasm_initial_state :unknown
    aasm_state :unknown
    aasm_state :pending
    aasm_state :completed

    attr_accessor :should_destroy, :status_message, :destroyed

    after_save :update_volumes
	after_destroy :mark_as_destroyed

    def should_destroy?
        should_destroy.to_i == 1
    end

	def mark_as_destroyed
	    self.destroyed = true
	end

    def enable!
        update_attribute(:is_enabled, true)
    end

    def disable!
        update_attribute(:is_enabled, false)
    end

    # for better performance, update volumes with the snapshot name
    def update_volumes
        Volume.update_all( ['snapshot_name=?', self.name], ['provider_account_id=? and snapshot_id=?', self.provider_account_id, self.snapshot_id ] )
    end

    def self.find_all_by_parent(parent, search, page, extra_joins, extra_conditions, sort=nil, filter=nil)
		send("find_all_by_#{ parent.class.to_s.underscore }", parent, search, page, extra_joins, extra_conditions, sort, filter)
	end

#    def self.find_all_by_cluster(cluster, search, page, extra_joins, extra_conditions, sort=nil, filter=nil)
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
  
    def self.find_all_by_provider_account(provider_account, search, page, extra_joins, extra_conditions, sort=nil, filter=nil)
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
        %w(name snapshot_id volume_id status start_time progress is_enabled device owner_id description)
    end

    def self.search_fields
        %w(name snapshot_id volume_id owner_id description)
    end
    
	def self.filter_fields
		%w(status owner_id)
	end

    def restore!(zone = nil, prefix = '')
		volume_name = prefix.blank? ? self.name : prefix+' '+self.name 
		volume = self.provider_account.volumes.build({
			:name => volume_name,
		})
		volume.save
        begin
			res = Ec2Adapter.create_volume(volume, self.snapshot_id, zone)
            volume.update_attributes(res)
            self.status_message = "restoring to volume '#{volume.name}'"
        rescue
			volume.destroy
            self.errors.add(:state, "#{$!}")
            self.status_message = "failed to restore snapshot '#{self.name}': #{$!}"
            return nil
        end
        return volume
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
            Ec2Adapter.delete_snapshot(self)
            self.status = 'deleting'
            self.status_message = 'delete requested'
		rescue
            self.errors.add(:state, "#{$!}")
            self.status_message = "failed to delete snapshot '#{self.name}': #{$!}"
            return false
        end
        
        return true
    end

end
