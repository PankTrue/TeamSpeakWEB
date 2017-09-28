env :PATH, ENV['PATH']

every '5 0 * * *' do
  runner 'Tsserver.update_servers', environment: "production"
end

every '0 6 * * *' do
  runner 'Tsserver.spam_info_for_extend', environment: "production"
end


