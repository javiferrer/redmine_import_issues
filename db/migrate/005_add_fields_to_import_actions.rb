class AddFieldsToImportActions < ActiveRecord::Migration
  def change
    add_column :import_actions, :fields, :text
  end
end
