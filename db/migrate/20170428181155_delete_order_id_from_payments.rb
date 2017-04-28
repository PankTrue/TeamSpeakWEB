class DeleteOrderIdFromPayments < ActiveRecord::Migration[5.0]
  def change
    remove_column :payments, :order_id, :integer
    add_column :payments, :orderid, :integer
  end
end
