
class Publisher < BaseModel
    belongs_to :provider_account
    has_many :publisher_parameters, :dependent => :destroy

    validates_associated :publisher_parameters

    after_update :save_publisher_parameters

    attr_accessor :should_destroy

    def should_destroy?
        should_destroy.to_i == 1
    end

    def save_publisher_parameters
        publisher_parameters.each do |i|
            if i.should_destroy?
                i.destroy
            else
                i.save(false)
            end
        end
    end

    def publisher_parameter_attributes=(publisher_parameter_attributes)
        publisher_parameter_attributes.each do |attributes|
            if attributes[:id].blank?
                publisher_parameters.build(attributes)
            else
                publisher_parameter = publisher_parameters.detect { |c| c.id == attributes[:id].to_i }
                publisher_parameter.attributes = attributes
            end
        end
    end

    def parameter_value(name)
        parameter = publisher_parameters.detect{|p| p.name == name}
        if parameter.nil?
            return nil
        else
            return parameter.value
        end
    end

	# Factory to create instances of subclasses
	def self.factory(klass_type, *params)
		class_name = klass_type.nil? ? 'Publisher' : klass_type

		# make sure the class is included first, and don't fail on error loading library
		require File.join(File.dirname(__FILE__), class_name.gsub(/::/, '/').downcase) rescue false

		_class = class_name.constantize rescue nil
		if not _class.nil? and _class.name == class_name
			return _class.new(*params)
		end

		# fallback to operation base
		return Publisher.new(params)
	end

	def class_type=(value) self[:type] = value; end
	def class_type() return self[:type]; end

    #methods should be overwritten in subclasses
    def initialize_parameters
        []
    end

    def options(name)
        []
    end

    def is_configuration_good?
    	self.state = "failed"
	    self.state_text = "is_configuration_good? method is not defined for this Publisher"
        return false
    end

    def publish!
	    self.state = "failed"
	    self.state_text = "publish! method is not defined for this Publisher"
	    return false
    end

    def self.label
        "Publisher"
    end
end
