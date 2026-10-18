Rails.application.routes.draw do
  resource :session, only: %i[ new create destroy ]
  resource :verification, only: %i[ new create ]
  resource :profile, only: %i[ edit update ]
  resources :saved_places, except: :show
  resource :driver_application, path: "drive", only: %i[ show edit update ]
  resources :documents, only: :show
  resources :fare_quotes, path: "ride", only: %i[ new create show ]
  resources :trips, only: %i[ create show ] do
    post :cancel, on: :member
  end
  get "places/search", to: "places#search", as: :search_places
  get "places/reverse", to: "places#reverse", as: :reverse_place

  get "driver", to: "driver_app#show", as: :driver_app
  namespace :api do
    namespace :v1 do
      namespace :driver do
        resource :state, only: :show do
          post :online
          post :offline
        end
        resources :offers, only: [] do
          member do
            post :accept
            post :decline
          end
        end
        resources :trips, only: [] do
          member do
            post :arrive
            post :start
            post :complete
            post :cancel
          end
        end
      end
    end
  end

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
