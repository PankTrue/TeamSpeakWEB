class Tsserver < ApplicationRecord
	belongs_to :user
	has_many :backups

	Payment_Data = {'1 месяц':1,'2 месяца':2, '3 месяца':3,'6 месяцев':6,'1 год':12}
	Ban_Data = {'ip':'ip', 'uid':'uid', 'Никнейм':'name'}

	validates :slots, presence: true, numericality: true, inclusion: {in: 10..512}
	validates :dns, uniqueness: true, allow_blank: true, format: {with: /\A[\w|-]+\z/, message: "не правильно введен" }
	validates :server_id,inclusion: {in: 0..Settings.other.ip.size,message: 'нет в списке'}



		def self.update_servers
			servers = []
			ts = Tsserver.all

			Settings.other.ip.size.times do |index|
				servers << Teamspeak::Functions.new(index)
			end

			ts.each do |t|
				if (Teamspeak::Other.sec2days(t.time_payment.to_time - Time.now) <= 0)
					u = User.find(t.user_id)
					cost = t.slots * Settings.other.slot_cost
					if (u.auto_extension and u.money >= cost)
						u.update money: u.money - cost
						t.update time_payment: Date.today + 30, state: true
						servers[t.server_id].server_autostart(t.machine_id, 1)
						servers[t.server_id].server_start(t.machine_id) unless servers[t.server_id].server_status(t.machine_id)
					elsif t.state
						t.update state: false
						servers[t.server_id].server_autostart(t.machine_id, 0)
						servers[t.server_id].server_stop t.machine_id if servers[t.server_id].server_status(t.machine_id)
					end
				end
			end

			Settings.other.ip.size.times do |index|
				servers[index].disconnect
			end
		end

		def self.spam_info_for_extend
			Tsserver.all.each do  |ts|
				if (0..4) === (Teamspeak::Other.sec2days(ts.time_payment.to_time - Time.now))
					user = User.where(id: ts.user_id).first
					if (!user.auto_extension) or (user.money < ts.slots * Settings.other.slot_cost)
						if (user.email !~ User::TEMP_EMAIL_REGEX)
							UserMailer.info_for_extend_server(user,ts).deliver_now
						else
							#TODO отправка писем в соц сеть
						end
					end
				end
			end
		end


end
