# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    registrations: 'overrides/registrations',
    sessions: 'overrides/sessions'
  }, skip: [:token_validations]

  resources :teams

  resources :users

  resources :apps, only: [:index, :create, :update, :show, :destroy] do
    resource :credentials, only: [:show, :update]
    collection do
      get 'name_suggestion'
      get 'stats/hourly'
    end
  end


  resources :webhooks do
    collection do
      get 'stats'
      get 'subscribe'
    end
    member do
      post 'send', action: :send_new
      post 'resend'
    end
  end

  resources :manifests

  resource :profile, only: [:show, :update]

  resources :members, only: [:index, :update, :show]

  resources :boards do
    member do
      post :clone
    end

    resources :flows, except: :index do
      resources :stages, except: :index
      resources :connections, except: :index
    end
  end

end
