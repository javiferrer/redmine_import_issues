class AddImportFieldToImportActions < ActiveRecord::Migration
  def change
    add_column :import_actions, :field_for_update, :integer
  end
end
