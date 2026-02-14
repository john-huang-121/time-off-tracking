Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  # Root route
  root "dashboard#index"

  devise_for :users

  # Dashboard
  get "dashboard", to: "dashboard#index"

  # Time Off Requests
  resources :time_off_requests do
    member do
      post :approve
      post :deny
      post :cancel
    end
  end

  # API routes
  namespace :api do
    namespace :v1 do
      resources :time_off_requests, only: [:index, :show, :create, :update, :destroy] do
        member do
          post :approve
          post :deny
          post :cancel
        end
      end

      resources :users, only: [:index, :show] do
        resources :time_off_requests, only: [:index]
      end

      resources :time_off_types, only: [:index, :show]
      resources :departments, only: [:index, :show]
    end
  end
end
