require 'base_model'

class AuditLog < BaseModel
    belongs_to :provider_account
    belongs_to :cluster
    belongs_to :author, :class_name => 'User'
    belongs_to :auditable, :polymorphic => true
    
    validates_presence_of :provider_account_name, :provider_account_id, :auditable_name, :auditable_type, :author_login, :summary

    attr_accessor :force
    serialize :changes, Hash

    before_create :skip_unchanged

    def skip_unchanged
        return false if read_attribute(:changes).blank? && force != true
        return true
    end
    private :skip_unchanged
    
	def self.search_by_author(author, options={})
		extra_joins = options[:joins]
		extra_conditions = options[:conditions]
		order = options[:order]
		joins = []
		joins = joins + extra_joins unless extra_joins.blank?

		conditions = ['('+table_name()+'.author_id = ? OR '+table_name()+'.author_login = ?)', author.id, author.login]
		unless extra_conditions.blank?
			extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
			conditions[0] << ' AND ' + extra_conditions[0]
			conditions << extra_conditions[1..-1]
		end
    
		order = table_name()+'.created_at DESC' if order.blank?

		options.merge!({
			:joins => joins,
			:conditions => conditions,
			:order => order,
		})

		search(options[:search], options[:page], options[:joins], options[:conditions], options[:order], options[:filter], options[:include])
	end
	
	# by default - find all logs concerning provider accounts and clusters visible to the user
	def self.options_for_find_by_user(user, options={})
		extra_joins = options[:joins]
		extra_conditions = options[:conditions]
		order = options[:order]
		joins = []
		joins = joins + extra_joins unless extra_joins.blank?

		conditions = ['1=0']
		if user.has_role?("admin")
			conditions = []
		else
			local_conditions = ['1=0']
			unless user.provider_accounts.empty?
				local_conditions << table_name()+".provider_account_id IN (#{user.provider_accounts.collect{|a| a.id}.join(',')})"
			end
			unless user.clusters.empty?
				local_conditions << table_name()+".cluster_id IN (#{user.clusters.collect{|a| a.id}.join(',')})"
			end
			conditions[0] = "(#{local_conditions.join(' OR ')})"
		end
    
		unless extra_conditions.blank?
			extra_conditions = [ extra_conditions ] if not extra_conditions.is_a? Array
			conditions[0] << ' AND ' + extra_conditions[0]
			conditions << extra_conditions[1..-1]
		end
    
		order = table_name()+'.created_at DESC' if order.blank?

		options.merge!({
			:joins => joins,
			:conditions => conditions,
			:order => order,
		})

		return options        
	end
	
	def self.create_for_parent(options)
        o = options[:parent]
        options.delete(:parent)
        
        o = o.server if o.respond_to?(:server)

        if !o.nil? and o.is_a?(Server)
            options[:server_name] ||= o.name
            options[:server_id] ||= o.id
        end
        o = o.cluster if !o.nil? and o.respond_to?(:cluster)

        if !o.nil? and o.is_a?(Cluster)
            options[:cluster_name] ||= o.name
            options[:cluster_id] ||= o.id
        end
        o = o.provider_account if !o.nil? and o.respond_to?(:provider_account)

        if !o.nil? and o.is_a?(ProviderAccount)
            options[:provider_account_name] ||= o.name
            options[:provider_account_id] ||= o.id
        end
        
        create(options)
	end

    def self.per_page
        10
    end

    def self.sort_fields
        %w(created_at author_login provider_account_name cluster_name server_name auditable_type auditable_name summary)
    end

    def self.search_fields
        %w(author_login provider_account_name cluster_name server_name auditable_name summary)
    end

    def self.filter_fields
        %w(author_id provider_account_id cluster_id server_id auditable_id auditable_type)
    end
end
