
class Message < BaseModel
	include AASM

	serialize :args, Hash
	
    belongs_to :provider_account
    belongs_to :operation
    
    validates_presence_of :provider_account_id
    validates_presence_of :message_id
	validates_presence_of :operation_id
	
	aasm_column :status
	aasm_initial_state :ok

	aasm_state :ok
	aasm_state :errored
	aasm_state :bounced

    def self.per_page
        20
    end

    def self.sort_fields
        %w(received_at sent_at provider_account_id message_id recipient sender handler state)
    end

    def self.search_fields
        %w(message_id recipient sender handler)
    end
end
