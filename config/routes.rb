Rails.application.routes.draw do
  get 'cabinet/new'
  post 'cabinet/create'

  get 'cabinet/destroy/:id', to: 'cabinet#destroy'
  get 'cabinet/home'

  get 'cabinet', to: 'cabinet#home'


  root 'home#index'

  get 'home/index'

  get 'home/about'
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
