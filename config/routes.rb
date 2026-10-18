Rails.application.routes.draw do
  resource :session, only: %i[ new create destroy ]
  resource :verification, only: %i[ new create ]
  resource :profile, only: %i[ edit update ]
  resources :saved_places, except: :show
  resource :driver_application, path: "drive", only: %i[ show edit update ]
  resources :documents, only: :show
  resources :fare_quotes, path: "ride", only: %i[ new create show ]
  get "places/search", to: "places#search", as: :search_places
  get "places/reverse", to: "places#reverse", as: :reverse_place

  namespace :admin do
    resources :tariffs, only: %i[ index update ]
    resources :service_zones, except: %i[ show destroy ]
    resources :driver_applications, only: %i[ index show ] do
      member do
        post :approve
        post :request_changes
        post :reject
        post :suspend
      end
    end
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
