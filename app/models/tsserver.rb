class Tsserver < ApplicationRecord
	belongs_to :user
	has_many :backups

	Payment_Data = {'1 месяц':1,'2 месяца':2, '3 месяца':3,'6 месяцев':6,'1 год':12}
	Ban_Data = {'ip':'ip', 'uid':'uid', 'Никнейм':'name'}

	validates :slots, presence: true, numericality: true, inclusion: {in: 10..512}
	validates :dns, uniqueness: true, allow_blank: true, format: {with: /\A[\w|-]+\z/, message: "не правильно введен" }

end
