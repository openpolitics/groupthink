Rails.application.routes.draw do
  
  resources :users
  resources :proposals
  
  root "proposals#index"
  
end
