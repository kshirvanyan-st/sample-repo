Rails.application.routes.draw do
  resource :session, only: %i[ new create destroy ]
  resource :verification, only: %i[ new create ]
  resource :profile, only: %i[ edit update ]
  resources :saved_places, except: :show

  namespace :admin do
    resources :users, only: :index do
      member do
        patch :role
        post :ban
        post :unban
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
  root "home#index"
end
