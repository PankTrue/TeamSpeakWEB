class AudiobotController < ApplicationController

  require 'socket'
  require 'net/ssh'
  require 'net/sftp'
  require 'timeout'

  before_action :authenticate_user!
  before_action :audiobot_params_for_create, only: [:create]
  before_action :audiobot_params_for_settings_up, only: [:settings_up]
  before_action :own_bot,only: [:edit,:update,:destroy,:panel, :settings,:settings_up,:extend, :extend_up, :restart, :playlist, :play_audio,:upload_audio_file]

  rescue_from Errno::ECONNREFUSED,Errno::ETIMEDOUT,Timeout::Error, :with => :invalid_manager
  rescue_from ActiveRecord::RecordInvalid, :with => :invalid_transaction


  def new
    @audiobot = Audiobot.new()
  end

  def create
    @audiobot = Audiobot.new(audiobot_params_for_create)

     unless [1,2,3,6,12].include?(params[:audiobot][:time_payment].to_i)
       redirect_to audiobot_new_path(@audiobot), warning: 'Не корректно выбрано время оплаты'
       return
     end

    @audiobot.user_id = current_user.id
    cost = params[:audiobot][:time_payment].to_i * Settings.audiobot.audio_quota_cost.to_f * params[:audiobot][:audio_quota].to_i
    @audiobot.time_payment = Date.today + 30 * params[:audiobot][:time_payment].to_i

    unless current_user.have_money?(cost)
      redirect_to cabinet_home_path, danger:'Недостаточно средств'
      return
    end
    unless @audiobot.valid?
      redirect_to audiobot_new_path(@audiobot),danger: 'Некоторые поля были введены неверно'
      return
    end

    ActiveRecord::Base.transaction do
      @audiobot.save!
      current_user.update!(money: ((current_user.money - cost).round(2)), spent: current_user.spent+cost)
      referall_system cost, current_user.ref
    end
    update_audiobot_cfg
    audiobot_start

    redirect_to cabinet_home_path, success: 'Вы успешно купили аудиобота'
  end

  def edit
    @days = Teamspeak::Other.sec2days(@audiobot.time_payment.to_time - Time.now)
  end

  def update
    days = Teamspeak::Other.sec2days(@audiobot.time_payment.to_time - Time.now)
    cost = (((params[:audiobot][:audio_quota].to_i - @audiobot.audio_quota) * (Settings.audiobot.audio_quota_cost.to_f/30*days))).round(2)

    unless current_user.have_money?(cost)
      redirect_to cabinet_home_path, danger: 'Недостаточно средст'
      return
    end
    unless @audiobot.valid?
      redirect_to audiobot_edit_path(@audiobot),warning: 'Не корректно выбрано время оплаты'
      return
    end

    ActiveRecord::Base.transaction do
      current_user.update!(money: ((current_user.money - cost).round 2), spent: current_user.spent+=cost)
      @audiobot.update!(audio_quota: params[:audiobot][:audio_quota].to_i)
      referall_system cost, current_user.ref
    end
    update_audiobot_cfg

    redirect_to audiobot_panel_path(params[:id]), success: 'Вы успешно редактировали бота'
  end

  def destroy
  end

  def panel
  end

  def settings
  end

  def settings_up
    ActiveRecord::Base.transaction do
      @audiobot.update!(audiobot_params_for_settings_up)
    end
    update_audiobot_cfg
    redirect_to audiobot_panel_path(@audiobot), success: 'Вы успешно изменили настройки бота'
  end

  def extend
  end

  def extend_up
    time_payment = params[:audiobot][:time_payment].to_i
    unless [1,2,3,6,12].include?(time_payment)
      redirect_to audiobot_extend_path(@audiobot), warning: 'Не корректно выбрано время оплаты'
      return
    end

    cost = @audiobot.audio_quota * Settings.audiobot.audio_quota_cost * time_payment

    unless current_user.have_money?(cost)
      redirect_to cabinet_home_path, danger: 'Недостаточно средств'
      return
    end

    current_user.spent+= cost
    current_user.money = current_user.money - cost
    @audiobot.state = true

    if Date.today <= @audiobot.time_payment
      @audiobot.time_payment = @audiobot.time_payment + time_payment * 30
    else
      @audiobot.time_payment = Date.today + time_payment * 30
    end

    ActiveRecord::Base.transaction do
      @audiobot.save!
      current_user.save!
      referall_system cost, current_user.ref
    end
    update_audiobot_cfg
    botslist_update

    redirect_to cabinet_home_path, success:'Вы успешно продлил'
  end

  def restart
    send_command_for_audiobot_manager('restart')
    redirect_to audiobot_panel_path(@audiobot.id), success: "Вы успешно перезапустили бота"
  end

  def playlist
    @playlist = getDecodedPlayList
    @for_decode = getSizeRawAudioFiles
  end

  def play_audio
    audiobot_play_audio(params[:audio_id]) unless params[:audio_id].blank?
    redirect_to audiobot_playlist_path(@audiobot.id), success: "Запись #{params[:audio_id].to_i} была успешно воспроизведена"
  end

  def upload_audio_file
    if(params[:audio_files].blank?)
      redirect_to audiobot_playlist_path(@audiobot.id), warning: 'Вы не выбрали файлы'
      return
    end

    full_size = 0
    (params[:audio_files] || []).each do |file|
      if((Audiobot::AUDIO_FORMATS_REGEXP =~ file.original_filename).nil?)
        (params[:audio_files] || []).each do |file|
          File.delete(file.tempfile.path)
        end
        redirect_to audiobot_playlist_path(@audiobot.id), warning: "Один из файлов не поддерживается. Список поддерживаемых форматов: #{Audiobot::AUDIO_FORMATS.join(',')}"
        return
      end
      full_size += file.size
    end

    total_decoded_size = getDecodedPlayList[:total]
    if(full_size > (@audiobot.audio_quota.megabytes - (total_decoded_size + getSizeRawAudioFiles)))
      (params[:audio_files] || []).each do |file|
        File.delete(file.tempfile.path)
      end
      redirect_to audiobot_playlist_path(@audiobot.id), danger: 'Вы привысили квоту на размер файлов'
      return
    end

    Net::SFTP.start(Settings.other.ip[@audiobot.server_id],Settings.other.ssh_user,password: Settings.other.ssh_password) do |sftp|
      (params[:audio_files] || []).each do |file|
        sftp.upload!(file.tempfile.path,"#{Settings.audiobot.path_for_audiobot}/data/#{@audiobot.id}/AudioFilesSource/#{file.original_filename}")
        File.delete(file.tempfile.path)
      end
    end
      redirect_to audiobot_playlist_path(@audiobot.id), success: 'Файл успешно загружен'
  end


private

  def own_bot
    @audiobot = Audiobot.find params[:id].to_i
    redirect_to cabinet_home_path, danger: 'Нет доступа' unless current_user.id == @audiobot.user_id or Settings.other.admin_list.include?(current_user.email)
  end

  def audiobot_params_for_create
      params.require(:audiobot).permit(:audio_quota, :time_payment,:address,:server_id)
  end

  def audiobot_params_for_settings_up
    params.require(:audiobot).permit(:address, :password, :nickname,:default_channel)
  end

  def update_audiobot_cfg
    send_command_for_audiobot_manager('config_update')
  end

  def botslist_update
    send_command_for_audiobot_manager('bots_list_update')
  end

  def audiobot_start
    send_command_for_audiobot_manager('start')
  end

  def audiobot_play_audio(audio_id)
    send_command_for_audiobot_manager("play_audio #{audio_id}")
  end

  def invalid_manager
    redirect_to home_index_path, danger:'Проблемы с сервером, сообщите об этом администрации'
  end

  def invalid_transaction
    redirect_to home_index_path, danger:'Что-то пошло не так, сообщите об этом администрации'
  end

  def send_command_for_audiobot_manager(message)
    Socket.tcp(Settings.other.ip[@audiobot.server_id],Settings.audiobot.manager_port,nil,nil,connect_timeout: 5) do |sock|
      sock.write("#{Settings.audiobot.verify_data}#{message} #{@audiobot.id}")
      Timeout::timeout(4) do
        raise Errno::ECONNREFUSED if(sock.gets()!= "OK")
      end
    end
  end

  def getDecodedPlayList
    data = {total: 0}
    Net::SFTP.start(Settings.other.ip[@audiobot.server_id],Settings.other.ssh_user,password: Settings.other.ssh_password) do |sftp|
      sftp.dir.entries("#{Settings.audiobot.path_for_audiobot}/data/#{@audiobot.id}/AudioFiles").each do |remote_file|
        unless(['.','..'].include?(remote_file.name))
          data[remote_file.name] = remote_file.attributes.size
          data[:total] += remote_file.attributes.size
        end
      end
    end
    return data
    # Net::SSH.start(Settings.other.ip[@audiobot.server_id],Settings.other.ssh_user,password: Settings.other.ssh_password) do |ssh|
    #   return ssh.exec!("ls -s1h #{Settings.audiobot.path_for_audiobot}/data/#{@audiobot.id}/AudioFiles").split("\n")
    # end
  end

  def getSizeRawAudioFiles
    data = ''
    Net::SSH.start(Settings.other.ip[@audiobot.server_id],Settings.other.ssh_user,password: Settings.other.ssh_password) do |ssh|
      data = ssh.exec!("du -sh #{Settings.audiobot.path_for_audiobot}/data/#{@audiobot.id}/AudioFilesSource/").split(' ')[0]
    end
    if(data[-1] == 'K')
      return data.to_i * 1024
    elsif(data[-1] == 'M')
      return data.to_i * 1048576
    elsif(data[-1] == 'G')
      return data.to_i * 1073741824
    end
  end

end
