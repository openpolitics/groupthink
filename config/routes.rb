Rails.application.routes.draw do
  
  resources :users
  resources :proposals
  
  get 'webhook', to: 'proposals#webhook', as: :webhook
  post 'update', to: 'proposals#update'
  
  root "proposals#index"
  
end
