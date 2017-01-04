Rails.application.routes.draw do

  resources :w1, only: [] do
    post :callback, on: :collection
    match :success, on: :collection, via: [:get, :post]
    match :fail, on: :collection, via: [:get, :post]
  end

  post 'cabinet/edit_auto_extension', to: 'cabinet#edit_auto_extension'
  post 'cabinet/free_dns', to: 'cabinet#free_dns'
  get 'cabinet/pay'
  get 'cabinet/new'
  post 'cabinet/create'
  delete 'cabinet/:id', to: 'cabinet#destroy', as: 'cabinet_destroy'
  get 'cabinet/home'
  get 'cabinet/extend/:id', to: 'cabinet#extend'
  post 'cabinet/extend_up/:id', to: 'cabinet#extend_up'
  post 'cabinet/work/:id', to: 'cabinet#work'
  get 'cabinet', to: 'cabinet#home'
  get 'cabinet/edit/:id', to: 'cabinet#edit', as: 'cabinet_edit'
  post 'cabinet/update/:id', to: 'cabinet#update', as: 'cabinet_update'
  get 'cabinet/backups/:id', to: 'cabinet#backups', as: 'cabinet_backups'
  post 'cabinet/create_backup'
  post 'cabinet/delete_backup'
  post 'cabinet/apply_backup'
  get 'cabinet/token/:id', to: 'cabinet#token', as: 'cabinet_token'
  post 'cabinet/create_token', to: 'cabinet#create_token', as: 'cabinet_create_token'
  post 'cabinet/delete_token', to: 'cabinet#delete_token', as: 'cabinet_delete_token'
  post 'cabinet/reset_permissions', to: 'cabinet#reset_permissions', as: 'cabinet_reset_permissions'
  get 'cabinet/settings/:id', to: 'cabinet#settings', as: 'cabinet_settings'
  post 'cabinet/settings_edit', to: 'cabinet#settings_edit', as: 'cabinet_settings_edit'
  get 'cabinet/bans/:id', to: 'cabinet#bans', as: 'cabinet_bans'
  post 'cabinet/ban', to: 'cabinet#ban', as: 'cabinet_ban'
  post 'cabinet/unban', to: 'cabinet#unban', as: 'cabinet_unban'
  post 'cabinet/unbanall', to: 'cabinet#unbanall', as: 'cabinet_unbanall'


  match '/ref/:ref' => 'home#ref', via: [:get, :post]
  get 'admin/info/:id', to: 'admin#info', as: 'admin_info'
  get 'admin/home'
  post 'admin/setmoney/:id', to: 'admin#setmoney'
  get 'admin/belongs_verification', to: 'admin#belongs_verification', as: 'admin_belongs_verification'
  get 'admin/user_list', to: 'admin#user_list', as: 'admin_user_list'
  get 'admin/servers', to: 'admin#servers', as: 'admin_servers'


  root 'home#index'
  get 'home/index'
  get 'home/about'


  devise_for :users, :controllers => {:registrations => "registrations"}
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
