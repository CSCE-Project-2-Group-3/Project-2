Rails.application.routes.draw do
  get "messages/create"
  get "conversations/index"
  get "conversations/show"
  get "conversations/create"
  # Devise authentication routes
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions",
    omniauth_callbacks: "users/omniauth_callbacks" }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :groups do
    post :join, on: :collection
    resources :expenses, only: [ :new, :create, :index ]
  end

  # Expense management routes
  resources :expenses do
    resources :comments, only: :create
    collection do
      post :bulk_upload
      get  :download_template
    end
  end
  
  # Conversation and messaging routes for user-to-user communication
  resources :conversations, only: [:index, :show, :create]
  resources :messages, only: [:create]

  # Category routes
  resources :categories, only: [ :index, :new, :create, :destroy ]
  resources :categories, only: [ :new, :create ]


  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # ✅ Root route – always goes to home page
  root to: "pages#home"
end
