require 'teamspeak-ruby'
module CabinetHelper

	class Server

		def server_worked?
			path = '/home/pank/Рабочий\ стол/teamspeak/ts3server_startscript.sh'
			if (%x'sh #{path} status') == "Server is running\n"
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
				ts.command('serverstop',sid: machine_id)
				ts.command('serverdelete',sid: machine_id)
				ts.disconnect
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

	end

end
