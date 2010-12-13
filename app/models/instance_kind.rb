class InstanceKind < ActiveRecord::Base
    belongs_to :instance_type_category
    validates_uniqueness_of :code_name, :scope => :instance_type_category_id
end
