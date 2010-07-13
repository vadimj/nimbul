
class IamCondition < BaseModel
    belongs_to :iam_statement
    validates_presence_of :type, :name, :value

    class_inheritable_accessor :operators
    class_inheritable_accessor :names

    serialize :value

    def self.allowed_operators(*operators)
        self.operators = operators
    end

    def self.allowed_names(*names)
        self.names ||= []
        self.names += names
    end

    allowed_names "aws:CurrentTime", "aws:SecureTransport", "aws:SourceIp"
end
