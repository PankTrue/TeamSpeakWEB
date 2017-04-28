class EditOrderId < ActiveRecord::Migration[5.0]
  def change
    remove_column :payments, :orderid, :integer
    add_column :payments, :order_id, :string
  end
end
