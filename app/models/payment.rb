class Payment < ApplicationRecord
  belongs_to :user

  validate :order_id, uniqueness: true

end
