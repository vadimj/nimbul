
class IamPolicy < BaseModel
    belongs_to :provider_account
    has_many :iam_statements

    validates_presence_of :provider_account_id, :name
    validates_length_of :name, :maximum => 128
    validates_uniqueness_of :name, :scope => :provider_account_id

    def statement
        statements = []
        self.iam_statements.each do |s|
            statements << s.to_aws_hash
        end
        statements.empty? ? nil : statements
    end

    def to_aws_hash
        include_attr = [
            :statement,
        ]
        attrs = self.attributes
        attrs[:statement] = self.statement
        attrs.delete_if{|key,value| value.nil? or !include_attr.include?(key.to_s.to_sym)}
        result = {}
        attrs.each_pair{ |key,value| result[key.to_s.camelize] = value }
        result
    end

    def to_aws_json
        self.to_aws_hash.to_json
    end
end
