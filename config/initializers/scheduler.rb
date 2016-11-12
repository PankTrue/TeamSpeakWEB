require 'rufus-scheduler'



s = Rufus::Scheduler.singleton



s.every '100m' do
  ts = Tsserver.all
  cab = CabinetHelper::Other.new()
    ts.each do |t|
      if cab.sec2days(t.time_payment.to_time - Time.now) <= 0
        t.update state: false
      end
    end
end
