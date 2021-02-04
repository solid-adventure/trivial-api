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
