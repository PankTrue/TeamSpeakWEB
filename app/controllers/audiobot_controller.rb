class AudiobotController < ApplicationController

  require 'socket'

  before_action :authenticate_user!
  before_action :audiobot_params_for_create, only: [:create]
  before_action :audiobot_params_for_settings_up, only: [:settings_up]
  before_action :own_bot,only: [:edit,:update,:destroy,:panel, :settings,:settings_up,:extend, :extend_up, :restart]

  def new
    @audiobot = Audiobot.new()
  end

  def create
    @audiobot = Audiobot.new(audiobot_params_for_create)

    if [1,2,3,6,12].include?(params[:audiobot][:time_payment].to_i)
      @audiobot.user_id = current_user.id
      cost = params[:audiobot][:time_payment].to_i * Settings.audiobot.audio_quota_cost.to_f * params[:audiobot][:audio_quota].to_i
      @audiobot.time_payment = Date.today + 30 * params[:audiobot][:time_payment].to_i
      @audiobot.server_id = params[:audiobot][:server_id].to_s
      if current_user.have_money?(cost)
        if @audiobot.valid?
          if @audiobot.save and current_user.update(money: ((current_user.money - cost).round(2)), spent: current_user.spent+cost)
            update_audiobot_cfg
            audiobot_start
            referall_system cost, current_user.ref
            redirect_to cabinet_home_path, success:'Вы успешно купили аудио бота'
          else
            redirect_to audiobot_new_path(@audiobot), danger: 'Что-то пошло не так, отпишите администрации чтобы они это починили.'
          end
        else
            render audiobot_new_path @audiobot
        end
      else
        redirect_to cabinet_home_path, danger:'Недостаточно средств'
      end
    else
      render 'new'
    end
  end

  def edit
    @days = Teamspeak::Other.sec2days(@audiobot.time_payment.to_time - Time.now)
  end

  def update
    days = Teamspeak::Other.sec2days(@audiobot.time_payment.to_time - Time.now)
    cost = (((params[:audiobot][:audio_quota].to_i - @audiobot.audio_quota) * (Settings.audiobot.audio_quota_cost.to_f/30*days))).round(2)
    if current_user.have_money?(cost)
      if @audiobot.valid?
        ActiveRecord::Base.transaction do
          current_user.update!(money: ((current_user.money - cost).round 2), spent: current_user.spent+=cost)
          @audiobot.update!(audio_quota: params[:audiobot][:audio_quota].to_i)
          referall_system cost, current_user.ref
        end
        update_audiobot_cfg
        redirect_to audiobot_panel_path(params[:id]), success: 'Вы успешно редактировали бота'
      else
        render 'cabinet/edit'
      end

    else
      redirect_to cabinet_home_path, danger: 'Недостаточно средст'
    end
  end

  def destroy
  end

  def panel
  end

  def settings
  end

  def settings_up
    if(@audiobot.update(audiobot_params_for_settings_up))
      update_audiobot_cfg
      redirect_to audiobot_panel_path(@audiobot), success: 'Вы успешно изменили настройки бота'
    else
      render 'audiobot/settings'
    end
  end

  def extend
  end

  def extend_up
    time_payment = params[:audiobot][:time_payment].to_i
    if [1,2,3,6,12].include?(time_payment)
      cost = @audiobot.audio_quota * Settings.audiobot.audio_quota_cost * time_payment
      if current_user.have_money?(cost)
        current_user.spent+= cost
        current_user.money = current_user.money - cost
        @audiobot.state = true
        if Date.today <= @audiobot.time_payment
          @audiobot.time_payment = @audiobot.time_payment + time_payment * 30
        else
          @audiobot.time_payment = Date.today + time_payment * 30
        end
          ActiveRecord::Base.transaction do
            @audiobot.save
            current_user.save
            referall_system cost, current_user.ref
          end
          update_audiobot_cfg

          redirect_to cabinet_home_path, success:'Вы успешно продлил'
      else
        redirect_to cabinet_home_path, danger: 'Недостаточно средств'
      end
    else
      redirect_to cabinet_home_path
    end
  end

  def restart
    TCPSocket.open(Settings.other.ip[@audiobot.server_id],Settings.audiobot.manager_port) do |sock|
      sock.write("#{Settings.audiobot.verify_data}restart #{@audiobot.id}")
    end
    redirect_to audiobot_panel_path(@audiobot.id), success: "Вы успешно перезапустили бота"
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
    TCPSocket.open(Settings.other.ip[@audiobot.server_id],Settings.audiobot.manager_port) do |sock|
      sock.write("#{Settings.audiobot.verify_data}config_update #{@audiobot.id}")
    end
  end

  def botslist_update
    TCPSocket.open(Settings.other.ip[@audiobot.server_id],Settings.audiobot.manager_port) do |sock|
      sock.write("#{Settings.audiobot.verify_data}bots_list_update")
    end
  end

  def audiobot_start
    TCPSocket.open(Settings.other.ip[@audiobot.server_id],Settings.audiobot.manager_port) do |sock|
      sock.write("#{Settings.audiobot.verify_data}start #{@audiobot.id}")
    end
  end

end
