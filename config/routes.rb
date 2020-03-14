# frozen_string_literal: true

Rails.application.routes.draw do
  authenticate :user, lambda { |u| u.admin? } do
    mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  end

  resources :users

  # Login
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
  devise_scope :user do
    get "sign_in", to: "devise/sessions#new", as: :new_user_session
    delete "sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
  end

  resources :proposals do
    member do
      post :comment
    end
  end

  resources :ideas do
  end

  post "webhook", to: "proposals#webhook", as: :webhook

  constraints(path: /[^\?]+/) do
    get "edit/:branch/*path", to: "edit#edit", format: false
    get "new/:branch", to: "edit#new", format: false
  end
  post "edit/message", to: "edit#message"
  post "edit/commit", to: "edit#commit"
  get "edit", to: "edit#index"

  root "proposals#index"
end
