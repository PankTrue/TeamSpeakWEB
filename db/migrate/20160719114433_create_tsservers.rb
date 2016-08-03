class CreateTsservers < ActiveRecord::Migration[5.0]
  def change
    create_table :tsservers do |t|
      t.integer :port, null: false              #Порт
      t.string :dns                             #Доменное имя
      t.integer :slots, null: false             #Количество слотов
      t.datetime :time_payment, null: false     #До какого оплачено
      t.integer :user_id,    null: false        #ID пользователя
      t.integer :machine_id, null: false        #ID виртуального сервера
      t.timestamps
    end
    add_index :tsservers, :user_id
  end
end
