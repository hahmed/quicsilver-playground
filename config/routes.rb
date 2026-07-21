Rails.application.routes.draw do
  root "home#show"

  webtransport "/transports/echo", to: EchoTransport

  get "up" => "rails/health#show", as: :rails_health_check
end
