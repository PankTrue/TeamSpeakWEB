class AddStateToTsservers < ActiveRecord::Migration[5.0]
  def change
    add_column :tsservers, :state, :boolean, default: true
  end
end
