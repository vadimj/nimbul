class OutMessage < Message
    validates_presence_of :recipient
	belongs_to :operations
	
    def send_message
        EventsAdapter.send_message(self)
    end
end
