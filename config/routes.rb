Rails.application.routes.draw do
  # get "messages/create"
  # get "conversations/index"
  # get "conversations/show"
  # get "conversations/create"
  # Devise authentication routes
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  resources :groups do
    post :join, on: :collection
    resources :expenses, only: [ :new, :create, :index ]
  end

  resources :expenses do
    resources :comments, only: :create
    collection do
      post :bulk_upload
      get :download_template
    end
  end

  resources :conversations, only: [ :index, :show, :create ]
  resources :messages, only: [ :create ]
  resources :categories, only: [ :new, :create ]

  get "dashboard", to: "pages#dashboard"
  resource :widget_summary, only: [ :show ]
  get "empty_modal", to: "widget_summaries#empty"

  # Health check endpoint for load balancers and uptime monitors
  get "up" => "rails/health#show", as: :rails_health_check

  root to: "pages#home"
end
