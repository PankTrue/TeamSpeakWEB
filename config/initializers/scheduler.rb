require 'rufus-scheduler'
require "#{Rails.root}/lib/teamspeak/teamspeak.rb"



server = Teamspeak::Functions.new
other = Teamspeak::Other.new
schedule = Rufus::Scheduler.singleton



schedule.cron '0 0 * * *' do
  ts = Tsserver.all
    ts.each do |t|
      if (other.sec2days(t.time_payment.to_time - Time.now) <= 0) and (t.state == true)
        t.update state: false
      end

      if t.state == false and server.server_status(t.machine_id) == 'Online'
        server.server_autostart t.machine_id, 0
        server.server_stop t.machine_id
      end
    end
end

#schedule.every '1m' do

  #cab.global_server_start

#end
