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
      get  :download_template
    end
  end

  # Category routes
  resources :categories, only: [:index, :new, :create, :destroy]

  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # ✅ Root route – always goes to home page
  root to: "pages#home"
end
