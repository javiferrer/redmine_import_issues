class AddTemplateIdToImportActions < ActiveRecord::Migration
  def change
    add_column :import_actions, :template_id, :integer
  end
end
