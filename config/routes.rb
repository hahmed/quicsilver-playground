Rails.application.routes.draw do
  root "home#show"

  resources :docs, param: :slug, only: [ :index, :show ] do
    resource :vote, only: :create, module: :docs
  end

  get "/drop", to: "drops#show"

  namespace :api do
    resource :status, only: :show, controller: :status
    resource :drop, only: :show, controller: :drop
    resources :drop_events, only: [ :index, :create ]
    resources :drop_claims, only: :create
    resources :messages, only: [ :index, :create ]
  end

  webtransport "/transports/echo", to: EchoTransport
  webtransport "/transports/drop", to: DropTransport

  get "up" => "rails/health#show", as: :rails_health_check
end
