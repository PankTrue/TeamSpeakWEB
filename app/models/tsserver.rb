class Tsserver < ApplicationRecord
	belongs_to :user

	validates :slots, presence: true
	validates :dns, uniqueness: true
end
