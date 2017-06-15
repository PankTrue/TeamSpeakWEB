require 'rufus-scheduler'
require "#{Rails.root}/lib/teamspeak/teamspeak.rb"



def sec2days(s)
  time = s.round
  time /= 60
  time /= 60
  time /= 24
  time+=2
end


schedule = Rufus::Scheduler.singleton


#schedule.every '10s' do    #for debug
schedule.cron '0 0 * * *' do
  server = Teamspeak::Functions.new
  ts = Tsserver.all
    ts.each do |t|
      if (sec2days(t.time_payment.to_time - Time.now) <= 0)
        u = User.where(id: t.user_id).take
        cost = t.slots * Settings.other.slot_cost
        if u.auto_extension and u.money >= cost
          u.update money: u.money - cost
          t.update time_payment: Date.today + 30, state: true
          server.server_start t.machine_id
        elsif t.state
          t.update state: false
        end
      end

      if t.state == false and server.server_status(t.machine_id)
        server.server_autostart t.machine_id, 0
        server.server_stop t.machine_id
      end
    end
  server.disconnect
end

#schedule.every '1m' do

  #cab.global_server_start

#end
