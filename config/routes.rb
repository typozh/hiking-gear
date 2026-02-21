# frozen_string_literal: true

Rails.application.routes.draw do
  # Health check
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Root path
  root 'dashboard#index'

  # Authentication
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'
  get 'signup', to: 'users#new'

  # User profile
  resource :user, only: [:show, :edit, :update]
  resources :users, only: [:create]

  # Trips with nested trip_gears
  resources :trips do
    resources :trip_gears, only: [:create, :update, :destroy]
  end

  # Gear items
  resources :gear_items

  # Gear imports
  resources :gear_imports, only: [:new, :create] do
    collection do
      get :map
      post :import_data
    end
  end

  # Gear categories (optional - for admin)
  resources :gear_categories, only: [:index, :show]
end
