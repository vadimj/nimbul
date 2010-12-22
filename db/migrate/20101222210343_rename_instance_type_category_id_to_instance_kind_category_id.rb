class RenameInstanceTypeCategoryIdToInstanceKindCategoryId < ActiveRecord::Migration
  def self.up
    rename_column :instance_kinds, :instance_type_category_id, :instance_kind_category_id
  end

  def self.down
    rename_column :instance_kinds, :instance_kind_category_id, :instance_type_category_id
  end
end
