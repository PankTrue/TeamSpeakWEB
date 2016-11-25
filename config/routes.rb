Rails.application.routes.draw do


  get 'report/index', to: 'report#index', as: 'report_index'
  get 'report/new', to: 'report#new', as: 'report_new'
  post 'report/create', to: 'report#create', as: 'report_create'
  get 'report/edit/:id', to: 'report#edit', as: 'report_edit'
  post 'report/update/:id', to: 'report#update', as: 'report_update'
  delete 'report/destroy/:id', to: 'report#destroy', as: 'report_destroy'

  get 'cabinet/new'
  post 'cabinet/create'
  delete 'cabinet/:id', to: 'cabinet#destroy'
  get 'cabinet/home'
  get 'cabinet/extend/:id', to: 'cabinet#extend'
  post 'cabinet/extend_up/:id', to: 'cabinet#extend_up'
  post 'cabinet/work/:id', to: 'cabinet#work'
  get 'cabinet', to: 'cabinet#home'
  get 'cabinet/edit/:id', to: 'cabinet#edit', as: 'cabinet_edit'
  post 'cabinet/update/:id', to: 'cabinet#update', as: 'cabinet_update'

  get 'admin/info/:id', to: 'admin#info', as: 'admin_info'
  get 'admin/home'
  post 'admin/setmoney/:id', to: 'admin#setmoney'


  root 'home#index'

  get 'home/index'

  get 'home/about'
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
