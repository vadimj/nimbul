
class KeyPair < BaseModel
    belongs_to :provider_account

	validates_presence_of :name
	validates_uniqueness_of :name, :scope => :provider_account_id

	def to_xml(options = {})
        default_only = [:id, :name, :fingerprint, :public_key, :created_at, :updated_at]
        options[:only] = (options[:only] || []) + default_only
        super(options)
    end

    attr_accessor :should_destroy

    def should_destroy?
        should_destroy.to_i == 1
    end

    # sort, search and paginate parameters
    def self.per_page
        10
    end

    def self.sort_fields
        %w(name)
    end

    def self.search_fields
        %w(name)
    end

end
