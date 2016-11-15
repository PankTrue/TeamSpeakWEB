require 'teamspeak-ruby'
module CabinetHelper

	class Server


		def initialize
			@ts_path = '/home/pank/Desktop/teamspeak'
			@ts_sctript_path = @ts_path + '/ts3server_startscript.sh'
			@dns_cfg_path = @ts_path + '/tsdns/tsdns_settings.ini'
			@dns_script_path = @ts_path + '/tsdnsserver'
		end

		def global_server_start
			unless server_worked?
				%x"sh #{@ts_sctript_path} start"
				return true
			else
				return false
			end
		end

		def server_worked?
			if (%x"sh #{@ts_sctript_path} status") == "Server is running\n"
				return true
			else
				return false
			end
		end

		def connect_server
			if server_worked?
				ts = Teamspeak::Client.new
				ts.login('serveradmin','fIKUs4uC')
				return ts
			else
				return 1
			end
		end

		def server_stop(machine_id)
			ts = connect_server
			if ts != 1
				ts.command('serverstop',sid: machine_id)
				ts.disconnect
			end
		end

		def server_start(machine_id)
			ts = connect_server
			if ts != 1
				ts.command('serverstart',sid: machine_id)
				ts.disconnect
			end
		end

		def server_create(port,slots)
			ts=connect_server
			if ts != 1
				temp=ts.command('servercreate',{virtualserver_name:'TeamSpeak\s]\p[\sServer',virtualserver_port: port,virtualserver_maxclients: slots})
				ts.disconnect
				return temp
			end
		end

		def server_destroy(machine_id)
			ts=connect_server
			if ts != 1
				if server_status(machine_id) == 'Online'
				ts.command('serverstop',sid: machine_id)
				ts.command('serverdelete',sid: machine_id)
				ts.disconnect
				else
					ts.command('serverdelete',sid: machine_id)
					ts.disconnect
				end
			end
		end

		def server_edit

		end

		def server_status(machine_id)
			ts=connect_server
			if ts != 1
				ts.command('use', {sid: machine_id}, '-virtual')
				info = ts.command('whoami')
				ts.disconnect
					if info['virtualserver_status'] == 'online'
						return 'Online'
					else
						return 'Offline'
					end
			else
				return 'Offline'
			end
		end

		def serverlist
			tmp=Array.new
			ts=connect_server
			if ts != 1
				ts.command('serverlist').each do  |temp|
					if temp.nil?
						break
					end
					tmp<<temp
				end
			ts.disconnect
			return tmp
			end
		end

		def sec2days(seсs)
			time = seсs.round
			time /= 60
			time /= 60
			time /= 24
			time+=2
		end

		def new_dns dns
			File.open(@dns_cfg_path, 'a') do |f|
				f.puts dns
			end
			%x"#{@dns_script_path} --update"
		end

		def edit_dns old_dns, new_dns
			arr = Array.new
			File.open @dns_cfg_path, "r" do |f|
				f.each_line do |l|
					arr << l
				end
			end

			arr[arr.index(old_dns+"\n")] = new_dns + "\n"
			arr.uniq!
			File.open @dns_cfg_path, "w" do |f|
				f.puts arr
			end
			%x"#{@dns_script_path} --update"
		end

		def del_dns dns
			arr = Array.new
			File.open @dns_cfg_path, "r" do |f|
				f.each_line do |l|
					arr << l
				end
			end

			arr.delete(dns+"\n")

			File.open @dns_cfg_path, "w" do |f|
				f.puts arr
			end
			%x"#{@dns_script_path} --update"
		end

		def dns_to_dnscfg dns, port
			"#{dns}.easy-ts.ru=127.0.0.1:#{port}"
		end


	end





end
