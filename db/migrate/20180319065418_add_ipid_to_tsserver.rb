class AddIpidToTsserver < ActiveRecord::Migration[5.0]
  def change
    add_column :tsservers, :server_id, :smallint, default: 0
     execute("UPDATE tsservers SET server_id = 0")
  end
end