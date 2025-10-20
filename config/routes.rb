Rails.application.routes.draw do
  resources :expenses do
    collection do
      post :bulk_upload
      get :download_template
    end
  end
  resources :categories, only: [:index, :new, :create, :destroy]
  root "expenses#index"
end
