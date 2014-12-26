class CreateImportActions < ActiveRecord::Migration
  def change
    create_table :import_actions do |t|
      t.integer :user_id
      t.integer :project_id
      t.string :status
      t.datetime :created_at
    end
  end
end
