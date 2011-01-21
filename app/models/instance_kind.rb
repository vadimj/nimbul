class InstanceKind < ActiveRecord::Base
    belongs_to :instance_kind_category
    
    validates_presence_of :instance_kind_category_id, :api_name, :name
    validates_uniqueness_of :api_name, :scope => :instance_kind_category_id
    
    attr_accessor :ram_gb
    
    def ram_gb
        return self.ram_mb if self.ram_mb.nil?
        gb = sprintf('%.2f', self.ram_mb.to_f/1024).to_f
        return gb
    end
end
