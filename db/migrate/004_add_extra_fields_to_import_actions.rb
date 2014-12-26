class AddExtraFieldsToImportActions < ActiveRecord::Migration
  def change
    add_column :import_actions, :headers, :text
    add_column :import_actions, :log, :text
    add_column :import_actions, :is_template, :boolean
    add_column :import_actions, :name, :string
    add_column :import_actions, :description, :text
    add_column :import_actions, :parent_id, :integer
  end
end
