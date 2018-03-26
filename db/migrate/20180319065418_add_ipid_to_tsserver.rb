class AddIpidToTsserver < ActiveRecord::Migration[5.0]
  def change
    add_column :tsservers, :server_id, :smallint, default: 0
  end
end