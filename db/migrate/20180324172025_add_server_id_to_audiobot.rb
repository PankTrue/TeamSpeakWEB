class AddServerIdToAudiobot < ActiveRecord::Migration[5.0]
  def change
    add_column :audiobots, :server_id, :smallint, default: 0
  end
end
