class CreateBackups < ActiveRecord::Migration[5.0]
  def change
    create_table :backups do |t|
      t.integer :tsserver_id, null: false
      t.text :data, null: false

      t.timestamps
    end
    add_index :backups, :ts_id
  end
end
