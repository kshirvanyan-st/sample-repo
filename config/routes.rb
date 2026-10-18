Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[ new create ]

  resources :onboarding, only: %i[ show update ], param: :step

  resources :profiles, only: :show do
    resource :follow, only: %i[ create destroy ]
    resource :block, only: %i[ create destroy ]
    resources :reports, only: %i[ new create ]
  end

  resource :discover, only: :show, controller: "discover"
  resources :likes, only: :create
  get "liked-me" => "likes#index", as: :liked_me
  resources :matches, only: %i[ index destroy ]

  scope module: :my do
    resource :profile, only: %i[ edit update ], as: :my_profile, path: "me"
  end

  resources :photos, only: %i[ index create destroy ] do
    patch :make_main, on: :member
  end
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
