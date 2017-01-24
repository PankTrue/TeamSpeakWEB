module CabinetHelper

	def sec2days(sec)
		time = sec.round
		time /= 60
		time /= 60
		time /= 24
		time+=2
	end





end
