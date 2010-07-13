
class LoadBalancerListener < BaseModel
    belongs_to :load_balancer
    validates_presence_of :load_balancer_port, :instance_port, :protocol

    attr_accessor :should_destroy

    def should_destroy?
        should_destroy.to_i == 1
    end
end
