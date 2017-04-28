class Rack::Attack

  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new # defaults to Rails.cache
  
  
  
  # ban_ip = []
  # unless File.file?("#{Rails.root}/log/iptables.list")
  #   File.open "#{Rails.root}/log/iptables.list", 'a' do |f|
  #     f.print ''
  #   end
  # end


  
  
  
  
  Rack::Attack.blocklist('allow2ban') do |req|
    Rack::Attack::Allow2Ban.filter(req.ip, :maxretry => 60, :findtime => 1.minute, :bantime => 10.minute) do
      req.ip == '127.0.0.1' ? false:true
    end
    end
  
  # Rack::Attack.blocklist('iptables') do |req|
  #   Rack::Attack::Allow2Ban.filter(req.ip, :maxretry => 600, :findtime => 1.minute, :bantime => 10.minute) do
  #       if req.ip == '127.0.0.1'
  #         return false
  #       else
  #         unless ban_ip.include?(req.ip)
  #           ban_ip << req.ip
  #           File.open("#{Rails.root}/log/iptables.list", 'a') do |f|
  #             f.puts req.ip
  #           end
  #         end
  #       end
  #   end
  # end


  Rack::Attack.blocklisted_response = lambda do |env|
    [ 403, {}, ['You are banned for a large number of requests']]
  end

  Rack::Attack.throttled_response = lambda do |env|
    [ 503, {}, ['Query limit exceeded!']]
  end




  throttle('panel', :limit => 5, :period => 10.second) do |req|
    req.ip if req.path == "/cabinet/panel/#{req.path.split('/').last}" or req.path == '/cabinet'
  end


end