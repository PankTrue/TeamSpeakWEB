class Rack::Attack

  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new # defaults to Rails.cache


  Rack::Attack.blocklist('allow2ban') do |req|
    Rack::Attack::Allow2Ban.filter(req.ip, :maxretry => 60, :findtime => 1.minute, :bantime => 10.minute) do
      req.ip == '127.0.0.1' ? false:true
    end
  end


  Rack::Attack.blocklisted_response = lambda do |env|
    # Using 503 because it may make attacker think that they have successfully
    # DOSed the site. Rack::Attack returns 403 for blocklists by default
    [ 403, {}, ['Blocked']]
  end




  throttle('panel', :limit => 5, :period => 10.second) do |req|
    req.ip if req.path == '/cabinet/panel/*'
  end


end