class AddAutoExtensionToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :auto_extension, :boolean, default: true
  end
end
