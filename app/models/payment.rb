class Payment < ApplicationRecord
  belongs_to :user

 validates :order_id, uniqueness: true

end
