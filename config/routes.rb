Rails.application.routes.draw do
  
  resources :users
  resources :proposals
  
  post 'webhook', to: 'proposals#webhook', as: :webhook
  post 'update', to: 'proposals#update'
  
  root "proposals#index"
  
end
