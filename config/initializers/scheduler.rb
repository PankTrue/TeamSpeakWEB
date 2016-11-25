require 'rufus-scheduler'


cab = CabinetHelper::Server.new
schedule = Rufus::Scheduler.singleton



#schedule.cron '0 0 * * *' do
schedule.every '20s' do

  ts = Tsserver.all
    ts.each do |t|
      if (cab.sec2days(t.time_payment.to_time - Time.now) <= 0) and (t.state == true)
        t.update state: false
      end

      if t.state == false and cab.server_status(t.machine_id) == 'Online'
        cab.server_autostart t.machine_id, 0
        cab.server_stop t.machine_id
      end
    end
end

schedule.every '10s' do

  cab.global_server_start

end
