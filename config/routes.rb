# frozen_string_literal: true

Rails.application.routes.draw do
  # Rails Event Store Browser (super_admin only)
  authenticate :user, ->(user) { user.has_role?(:super_admin) } do
    mount RubyEventStore::Browser::App.for(
      event_store_locator: -> { Rails.configuration.event_store },
      host: nil
    ) => "/res"
  end

  get "pages/landing"
  # Redirect to localhost from 127.0.0.1 to use same IP address with Vite server
  constraints(host: "127.0.0.1") do
    get "(*path)", to: redirect { |params, req| "#{req.protocol}localhost:#{req.port}/#{params[:path]}" }
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#landing"

  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions",
    passwords: "users/passwords",
    confirmations: "users/confirmations",
    invitations: "users/invitations",
  }

  get "dashboard", to: "home#index", as: :dashboard

  resources :projects do
    collection do
      get :search
    end
    member do
      post :switch
    end
  end

  resources :users, except: %i[new create] do
    member do
      delete :remove_from_project
    end
    collection do
      get :new_invitation
      post :invite
    end
  end

  resources :gemini_file_search_stores

  # Documents (both global and project-scoped via tenant)
  # Global scope: /documents?scope=global&store_id=X (admin only)
  # Project scope: /documents (uses current_project tenant)
  resources :documents, only: %i[index show new create destroy] do
    member do
      get :temporary_url
      get :file_url
    end
  end

  resources :chats, except: %i[edit] do
    resources :messages, only: %i[create]
  end

  resources :legal_cases do
    resources :case_notebooks, only: %i[index show new create update destroy] do
      resources :case_documents, only: %i[index show new create update destroy] do
        member do
          post :enable_ai
          post :disable_ai
          get :file_url
          get :file_content
        end
      end
    end

    resources :court_orders, only: %i[index show new create update destroy]

    resources :case_reminders, only: %i[index show new create update destroy] do
      member do
        post :acknowledge
      end
    end
  end
end
