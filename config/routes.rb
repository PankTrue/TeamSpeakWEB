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
  post 'cabinet/get_token', to: 'cabinet#get_token'

  get 'admin/info/:id', to: 'admin#info', as: 'admin_info'
  get 'admin/home'
  post 'admin/setmoney/:id', to: 'admin#setmoney'
  get 'admin/belongs_verification', to: 'admin#belongs_verification', as: 'admin_belongs_verification'
  get 'admin/user_list', to: 'admin#user_list', as: 'admin_user_list'


  root 'home#index'
  get 'home/index'
  get 'home/about'
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
