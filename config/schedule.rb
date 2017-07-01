job_type :rbenv_runner, %Q{export PATH=/home/pank/.rbenv/shims:/home/pank/.rbenv/bin:/usr/bin:$PATH; eval "$(rbenv init -)"; \
                         cd :path && :bundle_command :runner_command -e :environment ':task' :output }

every '0 18 * * *' do
  runner 'Tsserver.update_servers', environment: "production"
end

