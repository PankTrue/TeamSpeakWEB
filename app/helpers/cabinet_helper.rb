require 'teamspeak-ruby'
module CabinetHelper

	class Server 

		def server_create(port,slots)
			ts = Teamspeak::Client.new
			ts.login('serveradmin','9ilc4j2r')
			temp=ts.command('servercreate',{virtualserver_name:'TeamSpeak\s]\p[\sServer',virtualserver_port: port,virtualserver_maxclients: slots})
			ts.disconnect
			return temp
		end

		def server_destroy(machine_id)
			ts = Teamspeak::Client.new
			ts.login('serveradmin','9ilc4j2r')
			ts.command('serverstop',sid: machine_id)
			ts.command('serverdelete',sid: machine_id)
			ts.disconnect
		end

		def server_edit

		end

		def serverlist
			tmp=Array.new
			ts = Teamspeak::Client.new
			ts.login('serveradmin','9ilc4j2r')
			ts.command('serverlist').each do  |temp|
				tmp<<temp
			end
			ts.disconnect
			return tmp
		end

	end

end
