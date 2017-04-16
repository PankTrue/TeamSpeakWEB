class CabinetController < ApplicationController
helper CabinetHelper
require 'date'
require 'base64'
	before_action :authenticate_user!
	before_action :ts_params, only: [:create]
  before_action :own_server, only: [:panel, :settings_edit, :settings, :reset_permissions, :apply_backup, :delete_backup, :create_backup, :backups, :delete_token, :create_token, :token, :work, :extend_up, :extend, :destroy, :update, :edit]
  rescue_from Teamspeak::ServerError, :with => :invalid_server
  
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
  @days = sec2days(@ts.time_payment.to_time - Time.now)
end

def update
  unless params[:tsserver][:dns]==@ts.dns and params[:tsserver][:slots]==@ts.slots
      other = Teamspeak::Other.new
      days = sec2days(@ts.time_payment.to_time - Time.now)
      old_dns = @ts.dns
      cost = (((params[:tsserver][:slots].to_i - @ts.slots) * (3.to_f/30*days))).round 2
      cost += 10 if old_dns != params[:tsserver][:dns]
      if current_user.money >= cost
        if @ts.valid?
          if @ts.update dns: params[:tsserver][:dns], slots: params[:tsserver][:slots]
            server = Teamspeak::Functions.new
            current_user.update! money: ((current_user.money - cost).round 2), spent: current_user.spent+=cost
            referall_system cost, current_user.ref
            server.server_edit_slots @ts.machine_id, params[:tsserver][:slots]
            if !old_dns.empty? and !params[:tsserver][:dns].empty?
              other.edit_dns(old_dns, @ts.port,params[:tsserver][:dns],@ts.port)
            elsif !old_dns.empty? and params[:tsserver][:dns].empty?
              other.del_dns(old_dns, @ts.port)
            elsif old_dns.empty? and !params[:tsserver][:dns].empty?
              other.new_dns(params[:tsserver][:dns],@ts.port)
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
            @ts.port=data['virtualserver_port']
            @token=data['token']
            other.new_dns(@ts.dns, @ts.port) unless @ts.dns.empty?
            @ts.save
            user.money = (user.money - cost).round(2)
            user.save
            referall_system cost, current_user.ref
            redirect_to cabinet_home_path, success:'Вы успешно создали сервер', info:"Ваш ключ: #{@token}"
            server.disconnect
          else
             render cabinet_new_path @ts
          end
        else
          redirect_to cabinet_home_path, danger:'Недостаточно средств'
        end
    else
      render 'new'
    end

end



def destroy
        server=Teamspeak::Functions.new
        other = Teamspeak::Other.new
        dns, port = @ts.dns, @ts.port
        server.server_destroy(@ts.machine_id)
        other.del_dns(dns, port) unless dns.empty?
        b = Backup.where tsserver_id: @ts.id
        b.destroy_all
        if @ts.destroy
          redirect_to cabinet_home_path, success: 'Вы успешно удалили сервер'
        end
        server.disconnect

end

def extend

end

def extend_up
  user = current_user
  time = params[:tsserver][:time_payment].to_i
  cab = Teamspeak::Functions.new
  cost = @ts.slots * 3 * time
  if [1,2,3,6,12].include?(time)
    if user.money >= cost
        user.spent+= cost
        user.money = user.money - cost
        @ts.state = true
        if Date.today < @ts.time_payment
          @ts.time_payment = @ts.time_payment + time * 30
        else
          @ts.time_payment = Date.today + time * 30
          cab.server_start(@ts.machine_id)
          cab.server_autostart @ts.machine_id, 1
        end
        if @ts.save validate:false and user.save
          referall_system cost, current_user.ref
          redirect_to cabinet_home_path, success:'Вы успешно продлил'
        end
        cab.disconnect

    else
      redirect_to cabinet_home_path, danger: 'Недостаточно средств'
    end
  else
    redirect_to cabinet_home_path
  end
end

def work
        if @ts.state
          server=Teamspeak::Functions.new
          if server.server_status(@ts.machine_id)
            server.server_stop @ts.machine_id
            redirect_to cabinet_panel_path, success: 'Вы успешно выключили сервер'
          else
            server.server_start @ts.machine_id
            redirect_to cabinet_panel_path, success: 'Вы успешно включили сервер'
          end
          server.disconnect
        else
          redirect_to cabinet_home_path, warning: 'Продлите сервер'
        end
end


def token
      server = Teamspeak::Functions.new
      @tokens = server.token_list(@ts.machine_id)
      @groups = {}
      server.group_list(@ts.machine_id).each {|t| @groups.merge!({"#{t['name']}":t['sgid']}) if t["type"]==1}
      server.disconnect
end

def create_token
    server = Teamspeak::Functions.new
    server.create_token(@ts.machine_id, params[:group_id], params[:description])
    redirect_to cabinet_token_path(params[:id]), success: 'Вы успешно создали токен'
    server.disconnect
end

def delete_token
    server = Teamspeak::Functions.new
    server.delete_token @ts.machine_id, params[:token]
    redirect_to cabinet_token_path params[:id]
    server.disconnect
end

def pay

end

def pay_redirect
  if params[:money].to_i >= 5
    payment = Walletone::Payment.new(
        WMI_MERCHANT_ID:    Settings.w1.merchant_id,
        WMI_PAYMENT_AMOUNT:  params[:money], # Сумма
        WMI_CURRENCY_ID:     643, # ISO номер валюты (По умолчанию 643 - Рубль),
        WMI_DESCRIPTION: current_user.id
    )
    payment.sign! Settings.w1.signature

    @form = payment.form
  else
    redirect_to cabinet_pay_path, warning: 'Сумма должна быть больше или равна 5 рублей'
  end
end

def pay_unitpay
  redirect_to ''
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
    @backups = Backup.where(tsserver_id: params[:id])
end

def create_backup
  unless backup = Backup.where(tsserver_id: params[:id]).count >= 3
    server = Teamspeak::Functions.new
    backup = Backup.new(tsserver_id: params[:id], data: server.create_backup(@ts.machine_id).to_s)
    server.disconnect
    if backup.save
      redirect_to cabinet_backups_path(params[:id]), success: 'Вы успешно создали бекап!'
    else
      redirect_to cabinet_backups_path(params[:id]), danger: 'Что-то пошло не так'
    end

  else
    redirect_to cabinet_backups_path(params[:id]), warning: 'Вы превысили лимит бекапов'
  end
end

def delete_backup
    backup = Backup.find params[:backup_id]
    backup.destroy ? (redirect_to cabinet_backups_path(backup.tsserver_id), success: 'Вы успешно удалили!' ):(redirect_to cabinet_backups_path(backup.tsserver_id), danger: 'Что-то пошло не так')
end

def apply_backup
    backup = Backup.find params[:backup_id]
    server = Teamspeak::Functions.new
    server.deploy_backup(@ts.machine_id, backup.data)
    redirect_to cabinet_backups_path(backup.tsserver_id), success: 'Вы успешно применили бекап!'
    server.disconnect
end

def reset_permissions
    server = Teamspeak::Functions.new
    server.reset_permissions @ts.machine_id
    redirect_to cabinet_home_path, success: 'Вы успешно сбросили права'
    server.disconnect
end

def settings
    server = Teamspeak::Functions.new
    info = server.server_info @ts.machine_id
    @name, @welcome_message = info['virtualserver_name'], info['virtualserver_welcomemessage']
    server.disconnect
end

def settings_edit
    server = Teamspeak::Functions.new
    server.set_settings @ts.machine_id, params[:name], params[:welcome_message], params[:pass]
    redirect_to cabinet_panel_path(@ts.id), success: 'Вы успешно изменили настройки сервера'
    server.disconnect
end

# def bans
#   ts = Tsserver.where(id: params[:id]).select(:user_id, :machine_id).take
#   if current_user.id == ts.user_id
#     server = Teamspeak::Functions.new
#     @bans = server.bans_list ts.machine_id
#     server.disconnect
#   else
#     redirect_to root_path
#   end
# end

# def unban
#     server = Teamspeak::Functions.new
#     server.unban @ts.machine_id, params[:banid]
#     redirect_to cabinet_bans_path(params[:id]), success: 'Вы успешно разбанили пользователя'
#     server.disconnect
# end
#
# def unbanall
#     server = Teamspeak::Functions.new
#     server.unbanall @ts.machine_id
#     redirect_to cabinet_bans_path(params[:id]), success: 'Вы успешно разбанили всех'
#     server.disconnect
# end
#
# def ban
#     unless params[:param].blank? or params[:name].blank?
#       server = Teamspeak::Functions.new
#       server.ban(@ts.machine_id, [params[:param],params[:name]], params[:reasons],params[:duration])
#       redirect_to cabinet_bans_path params[:id]
#       server.disconnect
#     else
#       redirect_to cabinet_bans_path params[:id], warning: 'Не правильно заполнена форма'
#     end
# end

def ref
  @refs = 0
  @sum = 0
  User.all().each do |r|
    if r.ref == current_user.id
      @refs += 1
      @sum += r.spent * 0.1
    end
  end
end

def panel
    @count_users = 0
    server=Teamspeak::Functions.new
    server.command('use', {sid: @ts.machine_id}, '-virtual')
    @info=server.command('serverinfo', {}, '-virtual')
    @channel=server.command('channellist', {}, '-flags -voice -limits -virtual')
    @client=server.command('clientlist', {}, '-voice -virtual')
    # @server_group_list = server.command('servergrouplist', {}, '-virtual')
    #@channel_group_list = server.command('channelgrouplist', {}, '-virtual')
    server.disconnect
end

private
  
  def invalid_server
    redirect_to home_index_path, danger:'Проблемы с сервером, побробуйте позже'
  end

  def own_server
     @ts = Tsserver.find params[:id]
     redirect_to cabinet_home_path, danger: 'Нет доступа' unless current_user.id == @ts.user_id or Settings.other.admin_list.include?(current_user.email)
  end

	def ts_params
		params.require(:tsserver).permit(:slots, :dns, :time_payment)
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
