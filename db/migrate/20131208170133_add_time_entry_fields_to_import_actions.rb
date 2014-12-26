class AddTimeEntryFieldsToImportActions < ActiveRecord::Migration
  def change
    add_column :import_actions, :time_entry_fields, :text
  end
end
