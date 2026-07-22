Rails.application.routes.draw do
  root "home#show"

  namespace :api do
    resource :status, only: :show, controller: :status
    resources :messages, only: [:index, :create]
  end

  webtransport "/transports/echo", to: EchoTransport

  get "up" => "rails/health#show", as: :rails_health_check
end
