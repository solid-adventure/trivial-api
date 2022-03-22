# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    registrations: 'overrides/registrations',
    sessions: 'overrides/sessions'
  }, skip: [:token_validations]

  resources :users

  resources :apps, only: [:index, :create, :update, :show, :destroy] do
    resource :credentials, only: [:show] do
      put '', action: :update
      patch '', action: :patch
    end
    resource :api_key, only: [:create, :update]
    collection do
      get 'name_suggestion'
      get 'stats/hourly'
      get 'stats/daily'
      get 'stats/weekly'
    end
  end


  resources :webhooks do
    member do
      post 'send', action: :send_new
      post 'resend'
    end
  end

  resources :manifests do
    resources :drafts, only: [:create, :update, :show], controller: :manifest_drafts do
      member do
        get 'credentials'
        put 'credentials', action: :update_credentials
      end
    end
  end

  resource :profile, only: [:show, :update]

  get 'credential_sets', to: 'credential_sets#index'
  post 'credential_sets', to: 'credential_sets#create'
  get 'credential_sets/:id', to: 'credential_sets#show'
  put 'credential_sets/:id', to: 'credential_sets#update'
  patch 'credential_sets/:id', to: 'credential_sets#patch'
  delete 'credential_sets/:id', to: 'credential_sets#destroy'
  put 'credential_sets/:id/api_key', to: 'credential_sets#update_api_key'

end
