
class IamStatement < BaseModel
    belongs_to :iam_policy
    has_many :iam_conditions

    serialize :action

    def condition
        con = {}
        self.iam_conditions.each do |c|
            con[c.operator] = { c.name => c.value }
        end
        con.empty? ? nil : con
    end

    def to_aws_hash
        include_attr = [
            :effect,
            :action,
            :not_action,
            :resource,
            :not_resource,
            :condition,
        ]
        attrs = self.attributes
        attrs[:condition] = self.condition
        attrs.delete_if{|key,value| value.nil? or !include_attr.include?(key.to_s.to_sym)}
        result = {}
        attrs.each_pair{ |key,value| result[key.to_s.camelize] = value }
        result
    end
end
