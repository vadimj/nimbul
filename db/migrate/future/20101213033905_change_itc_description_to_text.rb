class ChangeItcDescriptionToText < ActiveRecord::Migration
    def self.up
        change_column :instance_type_categories, :description, :text
    end

    def self.down
        change_column :instance_type_categories, :description, :string
    end
end
