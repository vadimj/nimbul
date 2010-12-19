class InstanceKind < ActiveRecord::Base
    belongs_to :instance_kind_category
    
    validates_presence_of :instance_kind_category_id, :code_name, :name
    validates_uniqueness_of :code_name, :scope => :instance_kind_category_id
end
