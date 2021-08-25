require "sidekiq/web"

Rails.application.routes.draw do
  resources :downloads, only: [:index, :show, :new, :create, :kill] do
    member do
      delete "kill"
    end
  end
  get "/privacy", to: "home#privacy"
  get "/terms", to: "home#terms"
  mount Sidekiq::Web => "/sidekiq"

  resources :notifications, only: [:index]
  resources :announcements, only: [:index]

  root to: "downloads#index"
end
