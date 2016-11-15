require 'rufus-scheduler'


cab = CabinetHelper::Server.new
schedule = Rufus::Scheduler.singleton



schedule.cron '0 0 * * *' do

  ts = Tsserver.all
  cab = CabinetHelper::Server.new
    ts.each do |t|
      if (cab.sec2days(t.time_payment.to_time - Time.now) <= 0) and (t.state == true)
        t.update state: false
      end

      if t.state == false and cab.server_status(t.machine_id) == 'Online'
        cab.server_stop t.machine_id
      end
    end
end

schedule.every '1m' do

  if cab.global_server_start
    ts = Tsserver.all
    ts.each do |t|
      if t.state == false and cab.server_status(t.machine_id) == 'Online'
        cab.server_stop t.machine_id
      end
    end
  end

end
