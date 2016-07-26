Rails.application.routes.draw do
  
  resources :users
  resources :proposals
  
  post 'webhook', to: 'proposals#webhook', as: :webhook
  
  root "proposals#index"
  
end
