
class ServerProfile < BaseModel
    belongs_to :provider_account
    belongs_to :creator, :class_name => 'User'

    has_and_belongs_to_many :provider_accounts

    has_many :server_profile_revisions, :order => :revision, :dependent => :destroy
    has_many :server_profile_user_accesses, :dependent => :destroy
    has_many :users, :through => :server_profile_user_accesses

    validates_presence_of :name

	attr_accessor :should_destroy
	attr_accessor :status_message

    def should_destroy?
        should_destroy.to_i == 1
    end
    
    # sort, search and paginate parameters
    def self.per_page
        10
    end

    def self.sort_fields
        %w(name description creator_id)
    end

    def self.search_fields
        %w(name description)
    end

end
