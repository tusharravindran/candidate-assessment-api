Rails.application.routes.draw do
  # Platform admin UI — session-authenticated, not JWT
  mount RailsAdmin::Engine => "/admin", as: "rails_admin"

  # AdminUser Devise routes (sign_in/sign_out only — no registration from the web)
  devise_for :admin_users,
    path: "admin_auth",
    controllers: { sessions: "admin/sessions" },
    skip: [:registrations, :passwords]

  # Tenant recruiter JWT auth
  devise_for :recruiters,
    path: "api/v1/auth",
    path_names: {
      sign_in: "sign_in",
      sign_out: "sign_out",
      registration: "sign_up"
    },
    controllers: {
      sessions: "api/v1/auth/sessions",
      registrations: "api/v1/auth/registrations"
    }

  namespace :api do
    namespace :v1 do
      resource :organization, only: [:show, :update]

      resources :assessments do
        member do
          post :publish
          post :archive
        end
        resources :questions, shallow: true
      end

      resources :invitations, only: [:index, :create, :show, :destroy]

      namespace :candidate do
        get "session/:token", to: "sessions#show"
        post "session/:token/start", to: "sessions#start"
        post "session/:token/autosave", to: "sessions#autosave"
        post "session/:token/submit", to: "sessions#submit"
      end

      namespace :dashboard do
        get :stats, to: "stats#show"
        resources :results, only: [:index, :show] do
          member do
            patch :manual_review
          end
        end
      end

      get "search/candidates", to: "search#candidates"

      get "health", to: proc { [200, {}, [{ status: "ok" }.to_json]] }
    end
  end
end
