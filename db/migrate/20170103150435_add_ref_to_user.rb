class AddRefToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :ref, :integer, default: 0
  end
end
