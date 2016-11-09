class AddSpentNumberToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :spent, :float, default: 0.0
  end
end
