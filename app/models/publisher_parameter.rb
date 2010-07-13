
class PublisherParameter < BaseModel
    belongs_to :publisher
    validates_presence_of :type, :name, :value

    attr_accessor :should_destroy

    def should_destroy?
        should_destroy.to_i == 1
    end

    def options
        []
    end
end
