class CabinetController < ApplicationController
helper CabinetHelper
require 'date'
require 'base64'
	before_action :authenticate_user!
	before_action :ts_params, only: [:create]
  before_action :edit_params, only: [:update]
  before_action :extend_params, only: [:extend_up]


def home
    @servers = Tsserver.where(user_id: current_user.id).select(:machine_id)
    servs = Array.new
     @servers.each do |temp|
        servs << temp.machine_id
     end
    server = Teamspeak::Functions.new
    @status = server_status(server.server_list, servs)
    server.disconnect
end

def edit
  @ts = Tsserver.where(id: params[:id]).take!
  redirect_to root_path unless @ts.user_id == current_user.id or Settings.other.admin_list.include?(current_user.email)
  @days = sec2days(@ts.time_payment.to_time - Time.now)
end

def update
  @ts = Tsserver.where(id: params[:id]).take!
  unless edit_params[:dns]==@ts.dns and edit_params[:slots]==@ts.slots
    if current_user.id == @ts.user_id or Settings.other.admin_list.include?(current_user.email)
      other = Teamspeak::Other.new
      days = sec2days(@ts.time_payment.to_time - Time.now)
      old_dns = @ts.dns
      cost = (((edit_params[:slots].to_i - @ts.slots) * (3.to_f/30*days))).round 2
      cost += 10 if old_dns != edit_params[:dns]
      if current_user.money >= cost
        if @ts.valid?
          if @ts.update dns: edit_params[:dns], slots: edit_params[:slots]
            server = Teamspeak::Functions.new
            current_user.update! money: ((current_user.money - cost).round 2), spent: current_user.spent+=cost
            referall_system cost, current_user.ref
            server.server_edit_slots @ts.machine_id, edit_params[:slots]
            if !old_dns.empty? and !edit_params[:dns].empty?
              other.edit_dns(old_dns, @ts.port,edit_params[:dns],@ts.port)
            elsif !old_dns.empty? and edit_params[:dns].empty?
              other.del_dns(old_dns, @ts.port)
            elsif old_dns.empty? and !edit_params[:dns].empty?
              other.new_dns(edit_params[:dns],@ts.port)
            end
            redirect_to cabinet_home_path, success: 'Вы успешно редактировали сервер'
            server.disconnect
          else
            render 'cabinet/edit'
          end
        end
      else
        redirect_to cabinet_home_path, danger: 'Недостаточно средст'
      end
    else
      redirect_to root_path
    end
  else
    redirect_to cabinet_home_path, info: 'Вы ничего не изменили'
  end
end


def new
  @ts=Tsserver.new
end


def create
  server=Teamspeak::Functions.new
  other = Teamspeak::Other.new
    user = current_user
    @ts = Tsserver.new(ts_params)
    time = ts_params[:time_payment].to_i
    if [1,2,3,6,12].include?(time)

      @ts.time_payment = time
      @ts.user_id = user.id

      cost = time * 3 * @ts.slots

        if user.money >= cost
          if @ts.valid?
            user.spent+=cost
            @ts.time_payment = Date.today + 30*time
            data=server.server_create(free_port,@ts.slots)
            @ts.machine_id=data['sid']
            @ts.port =data['virtualserver_port']
            @token=data['token']
            other.new_dns(@ts.dns, @ts.port) unless @ts.dns.empty?
            @ts.save
            user.money = user.money - cost
            user.save
            referall_system cost, current_user.ref
            redirect_to cabinet_home_path, success:'Вы успешно создали сервер', info:"Ваш ключ: #{@token}"
            server.disconnect
          else
             render cabinet_new_path
          end
        else
          redirect_to cabinet_home_path, danger:'Недостаточно средств'
        end
    else
      render 'new'
    end

end



def destroy

    @ts = Tsserver.find(params[:id])
      if @ts.user_id == current_user.id or Settings.other.admin_list.include?(current_user.email)
        server=Teamspeak::Functions.new
        other = Teamspeak::Other.new
        dns, port = @ts.dns, @ts.port
        server.server_destroy(@ts.machine_id)
        other.del_dns(dns, port) unless dns.empty?
        if @ts.destroy
          redirect_to cabinet_home_path, success: 'Вы успешно удалили сервер'
        end
        server.disconnect
      else
        redirect_to root_path
      end

end

def extend
  @ts = Tsserver.where(id: params[:id]).take!
  redirect_to root_path unless @ts.user_id == current_user.id or Settings.other.admin_list.include?(current_user.email)
end

def extend_up
  s = Tsserver.where(id: params[:id]).take!
  user = current_user
  time = extend_params[:time_payment].to_i
  cab = Teamspeak::Functions.new
  if [1,2,3,6,12].include?(time)
    if user.money >= (s.slots * 3 * time)
      if user.id == s.user_id or Settings.other.admin_list.include?(current_user.email)
        user.spent+=(s.slots * 3 * time)
        user.money = user.money - (s.slots * 3 * time)
        s.state = true
        if Date.today < s.time_payment
          s.time_payment = s.time_payment + time * 30
        else
          s.time_payment = Date.today + time * 30
          cab.server_start(s.machine_id)
          cab.server_autostart s.machine_id, 1
        end
        if s.save validate:false and user.save
          referall_system cost, current_user.ref
          redirect_to cabinet_home_path, success:'Вы успешно продлил'
        end
        cab.disconnect

      else
        redirect_to root_path
      end
    else
      redirect_to cabinet_home_path, danger: 'Недостаточно средств'
    end
  else
    redirect_to cabinet_home_path
  end
end

def work
  ts = Tsserver.where(id: params[:id]).take!
  id = ts.machine_id
      if current_user.id == ts.user_id or Settings.other.admin_list.include?(current_user.email)
        if ts.state
          server=Teamspeak::Functions.new
          if server.server_status(id)
            server.server_stop id
            redirect_to cabinet_home_path, success: 'Вы успешно выключили сервер'
          else
            server.server_start id
            redirect_to cabinet_home_path, success: 'Вы успешно включили сервер'
          end
          server.disconnect
        else
          redirect_to cabinet_home_path, warning: 'Продлите сервер'
        end
      else
        redirect_to root_path
      end
end


def token
  @ts = Tsserver.where(id: params[:id]).select(:user_id, :id, :machine_id).take!
    if current_user.id==@ts.user_id
      server = Teamspeak::Functions.new
      @tokens = server.token_list(@ts.machine_id)
      @groups = {}
      server.group_list(@ts.machine_id).each {|t| @groups.merge!({"#{t['name']}":t['sgid']}) if t["type"]==1}
      server.disconnect
    else
      redirect_to root_path
    end
end

def create_token
  @ts = Tsserver.where(id: params[:id]).select(:user_id, :machine_id).take!
  if current_user.id==@ts.user_id
    server = Teamspeak::Functions.new
    server.create_token(@ts.machine_id, params[:group_id], params[:description])
    redirect_to cabinet_token_path(params[:id]), success: 'Вы успешно создали токен'
    server.disconnect
  else
    redirect_to root_path
  end
end

def delete_token
  @ts = Tsserver.where(id: params[:id]).select(:user_id, :machine_id).take!
  if current_user.id==@ts.user_id
    server = Teamspeak::Functions.new
    server.delete_token @ts.machine_id, params[:token]
    redirect_to cabinet_token_path params[:id]
    server.disconnect
  else
    redirect_to root_path
  end
end

def pay
  @w1 = Hash.new
  @w1 = {
      merchant_id: Settings_Walletone.merchant_id,
      description: "BASE64:#{Base64.encode64("Пополнение баланса user_id: #{current_user.id}")}",
      signature: generate_signature
  }

end

def free_dns
  dns_list = Tsserver.pluck(:dns)
  status = dns_list.include?(params[:dns]) ? true:false
  respond_to do |format|
    format.json { render :json => {status: status} }
  end
end

def edit_auto_extension
  unless current_user.auto_extension == params[:auto_extension]
    current_user.update auto_extension: params[:auto_extension]
  end
end

def backups
  @ts = Tsserver.where(id: params[:id]).select(:user_id, :id).take!
  if current_user.id == @ts.user_id
    @backups = Backup.where(tsserver_id: params[:id])
  else
    redirect_to root_path
  end
end

def create_backup
  unless backup = Backup.where(tsserver_id: 41).count >= 3
    ts = Tsserver.where(id: params[:tsserver_id]).select(:user_id, :machine_id).take!
  if current_user.id == ts.user_id
    server = Teamspeak::Functions.new
    backup = Backup.new(tsserver_id: params[:tsserver_id], data: server.create_backup(ts.machine_id).to_s)
    server.disconnect
    if backup.save
      redirect_to cabinet_backups_path(params[:tsserver_id]), success: 'Вы успешно создали бекап!'
    else
      redirect_to cabinet_backups_path(params[:tsserver_id]), danger: 'Что-то пошло не так'
    end
  else
    redirect_to root_path
  end
  else
    redirect_to cabinet_backups_path(params[:tsserver_id]), warning: 'Вы превысили лимит бекапов'
  end
end

def delete_backup
  backup = Backup.find params[:id]
  if current_user.id == Tsserver.where(id: backup.tsserver_id).select(:user_id).take.user_id
    backup.destroy ? (redirect_to cabinet_backups_path(backup.tsserver_id), success: 'Вы успешно удалили!' ):(redirect_to cabinet_backups_path(backup.tsserver_id), danger: 'Что-то пошло не так')
  else
    redirect_to root_path
  end
end

def apply_backup
  backup = Backup.find params[:id]
  ts = Tsserver.where(id: backup.tsserver_id).select(:user_id, :machine_id).take
  if current_user.id == ts.user_id
    server = Teamspeak::Functions.new
    server.deploy_backup(ts.machine_id, backup.data)
    redirect_to cabinet_backups_path(backup.tsserver_id), success: 'Вы успешно применили бекап!'
    server.disconnect
  else
    redirect_to root_path
  end
end

def reset_permissions
  ts = Tsserver.where(id: params[:id]).select(:user_id, :machine_id).take
  if current_user.id == ts.user_id
    server = Teamspeak::Functions.new
    server.reset_permissions ts.machine_id
    redirect_to cabinet_home_path, success: 'Вы успешно сбросили права'
    server.disconnect
  else
    redirect_to root_path
  end
end

def settings
  @ts = Tsserver.where(id: params[:id]).select(:user_id, :machine_id).take
  if current_user.id == @ts.user_id
    server = Teamspeak::Functions.new
    info = server.server_info @ts.machine_id
    @name, @welcome_message = info['virtualserver_name'], info['virtualserver_welcomemessage']
    server.disconnect
  else
    redirect_to root_path
  end
end

def settings_edit
  ts = Tsserver.where(id: params[:id]).select(:user_id, :machine_id).take
  if current_user.id == ts.user_id
    server = Teamspeak::Functions.new
    server.set_settings ts.machine_id, params[:name], params[:welcome_message], params[:pass]
    redirect_to cabinet_home_path, success: 'Вы успешно изменили настройки сервера'
    server.disconnect
  else
    redirect_to root_path
  end
end

def bans
  ts = Tsserver.where(id: params[:id]).select(:user_id, :machine_id).take
  if current_user.id == ts.user_id
    server = Teamspeak::Functions.new
    @bans = server.bans_list ts.machine_id
    server.disconnect
  else
    redirect_to root_path
  end
end

def unban
  ts = Tsserver.where(id: params[:id]).select(:user_id, :machine_id).take
  if current_user.id == ts.user_id
    server = Teamspeak::Functions.new
    server.unban ts.machine_id, params[:banid]
    redirect_to cabinet_bans_path(params[:id]), success: 'Вы успешно разбанили пользователя'
    server.disconnect
  else
    redirect_to root_path
  end
end

def unbanall
  ts = Tsserver.where(id: params[:id]).select(:user_id, :machine_id).take
  if current_user.id == ts.user_id
    server = Teamspeak::Functions.new
    server.unbanall ts.machine_id
    redirect_to cabinet_bans_path(params[:id]), success: 'Вы успешно разбанили всех'
    server.disconnect
  else
    redirect_to root_path
  end

end

def ban
  ts = Tsserver.where(id: params[:id]).select(:user_id, :machine_id).take
  if current_user.id == ts.user_id
    unless params[:param].blank? or params[:name].blank?
      server = Teamspeak::Functions.new
      server.ban(ts.machine_id, [params[:param],params[:name]], params[:reasons],params[:duration])
      redirect_to cabinet_bans_path params[:id]
      server.disconnect
    else
      redirect_to cabinet_bans_path params[:id], warning: 'Не правильно заполнена форма'
    end
  else
    redirect_to root_path
  end

end

private



  def edit_params
    params.require(:tsserver).permit(:slots, :dns)
  end

	def ts_params
		params.require(:tsserver).permit(:slots, :dns, :time_payment)
  end

  def extend_params
    params.require(:tsserver).permit(:time_payment)
  end




  def free_port
    i=2000
    server=Teamspeak::Functions.new
    data=server.server_list
    used_ports=[]
      data.each do |temp|
        used_ports << temp['virtualserver_port']
      end

    while true
      if used_ports.include?(i)
        i+=1
        next
      end
      ts = %x'lsof -i :#{i}'
      if ts.empty?
        return i
      else
        i+=1
      end
    end
    server.disconnect
  end

  def generate_signature
    data = params.clone
    data.delete('WMI_SIGNATURE')
    data = data.sort
    values = data.map {|key,val| val}
    signature_string = values + @options[:secret]
    Digest::MD5.base64digest(signature_string)
  end

  def server_status(server_list, user_servers)
    arr = Array.new
    server_list.each do |temp|
      if user_servers.include?(temp["virtualserver_id"])
        arr << temp["virtualserver_id"]
        arr << temp["virtualserver_status"]
      end
    end
    arr
  end

  def sec2days(sec)
    time = sec.round
    time /= 60
    time /= 60
    time /= 24
    time+=2
  end

  def referall_system cost, user_id
    if user_id != 0
      u = User.find user_id
      u.update money: (u.money+(cost*0.1).round(2))
    end
  end



end
