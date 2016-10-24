class Tsserver < ApplicationRecord
	belongs_to :user

	Payment_Data = {'1 месяц':1,'2 месяца':2, '3 месяца':3,'6 месяцев':6,'1 год':12}
	select_data = [1,2,3,6,12]

	validates :slots, :time_payment, presence: true
	validates :dns, uniqueness: true, allow_nil: true
	validates :time_payment, inclusion: {in: select_data}


end
