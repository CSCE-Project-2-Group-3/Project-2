Rails.application.routes.draw do
  # Devise authentication routes
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  # Expense management routes
  resources :expenses do
    collection do
      post :bulk_upload
      get :download_template
    end
  end

  # Category routes
  resources :categories, only: [:index, :new, :create, :destroy]

  # Health check endpoint (useful for uptime monitoring)
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA optional routes (uncomment if needed)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root page — currently showing expense dashboard after login
  root "expenses#index"
end
