class InMessage < Message
    validates_presence_of :sender, :received_at
end
