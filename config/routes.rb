Rails.application.routes.draw do

  
  class WalletoneMiddleware < Walletone::Middleware::Base
    def perform notify, env
      raise 'Wrong signature' unless notify.valid? Settings.w1.signature
        u = User.find(notify.WMI_DESCRIPTION.to_i)
        u.money = u.money+notify.WMI_PAYMENT_AMOUNT.to_i
        pay=Payment.new user_id: notify.WMI_DESCRIPTION.to_i, amount: notify.WMI_PAYMENT_AMOUNT.to_f, order_id: notify.fetch(:WMI_ORDER_ID).to_i
        if pay.save and u.save
          'Return some message for OK response'
        else
         raise 'Not saved'
        end
    end
  end


  mount WalletoneMiddleware.new => '/w1_callback'

  # scope :unitpay do
  #   get :success, to: 'unitpay#success'
  #   get :fail, to: 'unitpay#fail'
  #   get :notify, to: 'unitpay#notify'
  # end

  post 'cabinet/edit_auto_extension', to: 'cabinet#edit_auto_extension', as: 'cabinet_edit_auto_extension'
  post 'cabinet/free_dns', to: 'cabinet#free_dns', as: 'cabinet_free_dns'
  get 'cabinet/pay', to: 'cabinet#pay', as: 'cabinet_pay'
  get 'cabinet/new', to: 'cabinet#new', as: 'cabinet_new'
  post 'cabinet/create', to: 'cabinet#create', as: 'cabinet_create'
  delete 'cabinet/:id', to: 'cabinet#destroy', as: 'cabinet_destroy'
  get 'cabinet', to: 'cabinet#home', as: 'cabinet_home'
  get 'cabinet/extend/:id', to: 'cabinet#extend', as: 'cabinet_extend'
  post 'cabinet/extend_up/:id', to: 'cabinet#extend_up'
  post 'cabinet/work/:id', to: 'cabinet#work', as: 'cabinet_work'
  get 'cabinet/edit/:id', to: 'cabinet#edit', as: 'cabinet_edit'
  post 'cabinet/update/:id', to: 'cabinet#update', as: 'cabinet_update'
  get 'cabinet/backups/:id', to: 'cabinet#backups', as: 'cabinet_backups'
  post 'cabinet/create_backup'
  post 'cabinet/delete_backup'
  post 'cabinet/apply_backup'
  get 'cabinet/token/:id', to: 'cabinet#token', as: 'cabinet_token'
  post 'cabinet/create_token', to: 'cabinet#create_token', as: 'cabinet_create_token'
  post 'cabinet/delete_token', to: 'cabinet#delete_token', as: 'cabinet_delete_token'
  post 'cabinet/reset_permissions/:id', to: 'cabinet#reset_permissions', as: 'cabinet_reset_permissions'
  get 'cabinet/settings/:id', to: 'cabinet#settings', as: 'cabinet_settings'
  post 'cabinet/settings_edit', to: 'cabinet#settings_edit', as: 'cabinet_settings_edit'
  # get 'cabinet/bans/:id', to: 'cabinet#bans', as: 'cabinet_bans'
  # post 'cabinet/ban', to: 'cabinet#ban', as: 'cabinet_ban'
  # post 'cabinet/unban', to: 'cabinet#unban', as: 'cabinet_unban'
  # post 'cabinet/unbanall', to: 'cabinet#unbanall', as: 'cabinet_unbanall'
  get 'cabinet/pay_redirect', to: 'cabinet#pay_redirect', as: 'cabinet_pay_redirect'
  get 'cabinet/ref', to: 'cabinet#ref', as: 'cabinet_ref'
  get 'cabinet/panel/:id', to: 'cabinet#panel', as: 'cabinet_panel'

  get 'admin/info/:id', to: 'admin#info', as: 'admin_info'
  get 'admin/home', to: 'admin#home', as: 'admin_home'
  post 'admin/setmoney/:id', to: 'admin#setmoney'
  get 'admin/belongs_verification', to: 'admin#belongs_verification', as: 'admin_belongs_verification'
  get 'admin/user_list', to: 'admin#user_list', as: 'admin_user_list'
  get 'admin/servers', to: 'admin#servers', as: 'admin_servers'
  get 'admin/del_physical_server', to: 'admin#del_physical_server', as: 'admin_del_physical_server'
  get 'admin/amounts', to: 'admin#amounts', as: 'admin_amounts'
  get 'admin/panel', to: 'admin#panel', as: 'admin_panel'
  get 'admin/print_data', to: 'admin#print_data', as: 'admin_print_data'
  get 'admin/panel_info', to: 'admin#panel_info', as: 'admin_panel_info'


  match '/ref/:ref' => 'home#ref', via: [:get, :post]
  get '/home/regulations' => 'home#regulations', as: 'home_regulations'
  root 'home#index'
  get 'home/index'
  get 'home/news'


  devise_for :users, :controllers => {registrations: "registrations", passwords: "passwords", sessions: "sessions"}
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
