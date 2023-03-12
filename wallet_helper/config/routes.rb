Rails.application.routes.draw do
  root "home#index"

  resources :address, only: [:index]
end
