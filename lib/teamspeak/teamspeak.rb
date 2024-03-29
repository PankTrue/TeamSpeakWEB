require 'socket'

module Teamspeak

  class ServerError < StandardError
    attr_reader(:code, :message)

    def initialize(code, message)
      @code = code
      @message = message
      Rails.logger.error "TeamspeakError - [#{Time.now().strftime('%Y-%m-%d %H:%M:%S')}] #{@code} #{@message}"
    end
  end




  class Client
    # access the raw socket
    attr_reader(:sock)


    # First is escaped char, second is real char.
    SPECIAL_CHARS = [
        ['\\\\', '\\'],
        ['\\/', '/'],
        ['\\s', ' '],
        ['\\p', '|'],
        ['\\a', '\a'],
        ['\\b', '\b'],
        ['\\f', '\f'],
        ['\\n', '\n'],
        ['\\r', '\r'],
        ['\\t', '\t'],
        ['\\v', '\v']
    ].freeze

    # Initializes Client
    #
    #   connect('voice.domain.com', 88888)
    def initialize(host = 'localhost', port = 10_011)
      connect(host, 10_011)
      login(Settings.teamspeak.login,Settings.teamspeak.password)
    end


    # Connects to a TeamSpeak 3 server
    #
    #   connect('voice.domain.com', 88888)
    def connect(host = 'localhost', port = 10_011)
      begin
        @sock = TCPSocket.new(host, port)
      rescue
        # %x"sh #{Settings.teamspeak.ts_path}/ts3server_startscript.sh start"
        # %x"#{Settings.teamspeak.ts_path}/test"
        raise ServerError.new('Error', 'Global server is not running')
      end
      # Check if the response is the same as a normal teamspeak 3 server.
      if @sock.gets.strip != 'TS3'
        raise ServerError.new("Error", 'Socket not TS3')
      end

      # Remove useless text from the buffer.
      @sock.gets
    end

    # Disconnects from the TeamSpeak 3 server
    def disconnect
      @sock.puts 'quit'
      @sock.close
    end

    # Authenticates with the TeamSpeak 3 server
    #
    #   login('serveradmin', 'H8YlK1f9')
    def login(user, pass)
      command('login', client_login_name: user, client_login_password: pass)
    end

    # Sends command to the TeamSpeak 3 server and returns the response
    #
    #   command('use', {'sid' => 1}, '-away')
    def command(cmd, params = {}, options = '')
      out = ''
      response = ''

      out += cmd

      params.each_pair do |key, value|
        out += " #{key}=#{encode_param(value.to_s)}"
      end

      out += ' ' + options

      @sock.puts out

      if cmd == 'servernotifyregister'
        2.times { response += @sock.gets }
        return parse_response(response)
      end

      loop do
        response += @sock.gets
        break if response.index(' msg=')
      end

      # Array of commands that are expected to return as an array.
      # Not sure - clientgetids
      should_be_array = %w(
        bindinglist serverlist servergrouplist servergroupclientlist
        servergroupsbyclientid servergroupclientlist logview channellist
        channelfind channelgrouplist channelgroupclientlist channelgrouppermlist
        channelpermlist clientlist clientfind clientdblist clientdbfind
        channelclientpermlist permissionlist permoverview privilegekeylist
        messagelist complainlist banlist ftlist custominfo permfind
      )

      parsed_response = parse_response(response)

      should_be_array.include?(cmd) ? parsed_response : parsed_response.first
    end


    def parse_response(response)
      out = []

      response.split('|').each do |key|
        data = {}

        key.split(' ').each do |inner_key|
          value = inner_key.split('=', 2)

          data[value[0]] = decode_param(value[1])
        end

        out.push(data)
      end

      check_response_error(out)

      out
    end

    def decode_param(param)
      return nil unless param
      # Return as integer if possible
      return param.to_i if param.to_i.to_s == param

      SPECIAL_CHARS.each do |pair|
        param = param.gsub(pair[0], pair[1])
      end

      param
    end

    def encode_param(param)
      SPECIAL_CHARS.each do |pair|
        param = param.gsub(pair[1], pair[0])
      end

      param
    end

    def check_response_error(response)
      id = response.first['id'] || 0
      message = response.first['msg'] || 0

      raise ServerError.new(id, message) unless id == 0 or id == 1281
    end


    private(
        :parse_response, :decode_param, :encode_param,
        :check_response_error
    )
  end

  class Functions < Client

    def initialize(server_id)
      super(Settings.other.ip[server_id])
    end

    def info
      self.command('use', {sid: 52}, '-virtual')
      self.command('whoami')
    end

    def server_stop machine_id
      self.command('serverstop',sid: machine_id)
    end

    def server_start machine_id
      self.command('serverstart',sid: machine_id)
    end

    def server_create port,slots
      self.command('servercreate',{virtualserver_name:'TeamSpeak\s]\p[\sServer',virtualserver_port: port,virtualserver_maxclients: slots})
    end

    def server_status machine_id
      self.command('use', {sid: machine_id}, '-virtual')
      self.command('whoami')['virtualserver_status'] == 'online' ? true : false
    end

    def server_autostart machine_id, state
      self.command('use', {sid: machine_id}, '-virtual' )
      self.command('serveredit', 'virtualserver_autostart': state)
    end

    def server_edit_slots machine_id, slots
      self.command('use', sid: machine_id)
      self.command('serveredit', 'virtualserver_maxclients':slots)
    end

    def server_destroy machine_id
      machine_id = machine_id.to_i
      if server_status machine_id
        self.command('serverstop',sid: machine_id)
        self.command('serverdelete',sid: machine_id)
      else
        self.command('serverdelete',sid: machine_id)
      end
    end

    def group_list machine_id
      self.command('use', sid: machine_id)
      self.command('servergrouplist')
    end

    def token_list machine_id
      self.command('use', sid: machine_id)
      self.command('privilegekeylist')
    end

    def create_token machine_id, group_id, description
      self.command('use', sid: machine_id)
      self.command('privilegekeyadd', {tokentype: 0, tokenid1: group_id, tokenid2: 0, tokendescription: description})
    end

    def delete_token machine_id, token
      self.command('use', sid: machine_id)
      self.command('privilegekeydelete', token: token)
    end

    def create_backup machine_id
      self.command 'use', sid: machine_id
      @sock.puts 'serversnapshotcreate'
      data = @sock.gets
      loop do
        response = @sock.gets
        break if response.index(' msg=')
      end
      data
    end

    def deploy_backup machine_id, data
      self.command 'use', sid: machine_id
      @sock.puts "serversnapshotdeploy #{data}"
      loop do
        response = @sock.gets
        break if response.index(' msg=')
      end
    end

    def reset_permissions machine_id
      self.command 'use', sid: machine_id
      self.command 'permreset'
    end

    def set_settings machine_id, name,welcome_message, password
      self.command 'use', sid: machine_id
      self.command 'serveredit', {virtualserver_name: name,virtualserver_welcomemessage: welcome_message, virtualserver_password: password }
    end

    def bans_list machine_id
      self.command 'use', sid: machine_id
      self.command 'banlist'
    end

    def ban machine_id, param, time, reason
      self.command 'use', sid: machine_id
      self.command "banadd #{param[0]}=#{param[1]}", {time:time+' sec', banreason: reason}
    end

    def unban machine_id, id
      self.command 'use', sid: machine_id
      self.command 'bandel', banid: id
    end

    def unbanall machine_id
      self.command 'use', sid: machine_id
      self.command 'bandelall'
    end

    def server_list
      tmp=Array.new
      self.command('serverlist', {}, '-short').each do |temp|
        break if temp.blank?
        tmp << temp
      end
      return tmp
    end

    def server_info machine_id
      self.command 'use', sid: machine_id
      self.command 'serverinfo'
    end

    def client_list machine_id
      self.command 'use', sid: machine_id
      self.command 'clientlist'
    end

    def channel_list machine_id
      self.command 'use', sid: machine_id
      self.command 'channellist'
    end


  end

  class Other
      @@ip = '127.0.0.1'

    def self.sec2days(s)
      time = s.round
      time /= 60
      time /= 60
      time /= 24
      time+=2
    end

    def self.new_dns dns, port,server_id
      File.open("#{Settings.teamspeak.ts_path}/tsdns/tsdns_settings.ini", 'a') do |f|
        f.puts dns_to_dnscfg(dns, port,server_id)
      end
      %x"#{Settings.teamspeak.ts_path}/tsdns/tsdnsserver --update"
    end

    def self.edit_dns old_dns, old_port, new_dns, new_port,server_id
      arr = Array.new
      File.open "#{Settings.teamspeak.ts_path}/tsdns/tsdns_settings.ini", "r" do |f|
        f.each_line do |l|
          arr << l
        end
      end
      index = arr.index(dns_to_dnscfg(old_dns, old_port,server_id)+"\n")
      unless index.nil?
        arr[index] = dns_to_dnscfg(new_dns, new_port,server_id).to_s + "\n"
      end

      arr.uniq!
      File.open "#{Settings.teamspeak.ts_path}/tsdns/tsdns_settings.ini", "w" do |f|
        f.puts arr
      end
      %x"#{Settings.teamspeak.ts_path}/tsdns/tsdnsserver --update"
    end

    def self.del_dns dns, port,server_id
      arr = Array.new
      File.open "#{Settings.teamspeak.ts_path}/tsdns/tsdns_settings.ini", "r" do |f|
        f.each_line do |l|
          arr << l
        end
      end

      arr.delete(dns_to_dnscfg(dns, port, server_id)+"\n")

      File.open "#{Settings.teamspeak.ts_path}/tsdns/tsdns_settings.ini", "w" do |f|
        f.puts arr
      end
      %x"#{Settings.teamspeak.ts_path}/tsdns/tsdnsserver --update"
    end

    def self.dns_to_dnscfg dns, port,server_id
      "#{dns}.#{Settings.other.dns}=#{Settings.other.ip[server_id]}:#{port}"
    end

  end
end

