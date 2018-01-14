class CreateAudiobots < ActiveRecord::Migration[5.0]
  def change
    create_table :audiobots do |t|
      t.date    :time_payment, null: false
      t.integer :user_id
      t.string  :address
      t.string :password
      t.integer :audio_quota, null: false
      t.string :nickname
      t.integer :default_channel
      t.timestamps
    end
    add_index :audiobots, :user_id
  end
end
