Rails.application.routes.draw do
  get 'admin/home'

  get 'cabinet/new'
  post 'cabinet/create'

  delete 'cabinet/:id', to: 'cabinet#destroy'
  get 'cabinet/home'
  get 'cabinet/extend/:id', to: 'cabinet#extend'
  post 'cabinet/extend_up/:id', to: 'cabinet#extend_up'
  post 'cabinet/work/:id', to: 'cabinet#work'

  get 'cabinet', to: 'cabinet#home'


  root 'home#index'

  get 'home/index'

  get 'home/about'
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
