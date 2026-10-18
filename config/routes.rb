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
  resources :matches, only: %i[ index destroy ] do
    resource :conversation, only: :create
  end

  resources :streams, only: %i[ index show create ], path: "live" do
    member do
      get :studio
      patch :finish
    end
    resources :comments, only: %i[ create destroy ], controller: "stream_comments"
  end
  get "go-live" => "streams#new", as: :go_live
  patch "go-live/key" => "streams#reset_key", as: :reset_stream_key

  resources :conversations, only: %i[ index show ], path: "chats" do
    patch :read, on: :member
    resources :messages, only: :create
  end

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

  # Called by MediaMTX (see config/media/mediamtx.yml).
  namespace :media do
    post "auth" => "auth#create"
    post "hooks/ready" => "hooks#ready"
    post "hooks/not_ready" => "hooks#not_ready"
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
