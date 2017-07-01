every '10 19 * * *' do
  runner 'Tsserver.update_servers', environment: "production"
end

