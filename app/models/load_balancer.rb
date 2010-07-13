
class LoadBalancer < BaseModel
    belongs_to :provider_account
    has_and_belongs_to_many :zones

    has_many :load_balancer_listeners

    validates_presence_of :load_balancer_name

    after_update :save_load_balancer_listeners

    attr_accessor :should_destroy

    def should_destroy?
        should_destroy.to_i == 1
    end

    def save_load_balancer_listeners
        load_balancer_listeners.each do |i|
            if i.should_destroy?
                i.destroy
            else
                i.save(false)
            end
        end
    end

end
