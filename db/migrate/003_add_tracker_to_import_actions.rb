class AddTrackerToImportActions < ActiveRecord::Migration
  def change
    add_column :import_actions, :tracker_id, :integer
  end
end
