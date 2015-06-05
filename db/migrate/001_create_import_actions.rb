class CreateImportActions < ActiveRecord::Migration
  def change
    create_table :import_actions do |t|

      t.integer :user_id

      t.integer :project_id

      t.string :status

      t.datetime :created_at

      t.integer :tracker_id

      t.text :headers

      t.text :log

      t.boolean :is_template

      t.string :name

      t.text :description

      t.integer :parent_id

      t.text :fields

      t.integer :field_for_update

      t.integer :template_id

      t.text :time_entry_fields


    end

  end
end
