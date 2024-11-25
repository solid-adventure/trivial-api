# frozen_string_literal: true

Rails.application.routes.draw do
  concern :auditable do
    resources :audits, only: [:index, :show] do
      collection do
        get '', to: 'audits#index', constraints: { format: :html }
        get '', to: 'audits#csv', constraints: { format: :csv }
      end
    end
  end

  resources :customers
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    registrations: 'overrides/registrations',
    sessions: 'overrides/sessions',
    passwords: 'overrides/passwords'
  }, skip: [:token_validations, :invitations]

  # only generate the manually designated routes
  devise_for :users, path: "auth", only: [], controllers: { invitations: 'overrides/invitations' }
  devise_scope :user do
    post 'auth/invitation', to: 'overrides/invitations#create', as: :user_invite
    put 'auth/invitation', to: 'overrides/invitations#update', as: :accept_invite
  end

  resources :users

  resources :organizations, concerns: :auditable do
    member do
      delete 'delete_org_role'
    end
  end

  resources :apps, concerns: :auditable, only: [:index, :create, :update, :show, :destroy] do
    collection do
      get 'name_suggestion'
      get 'activity_stats', to: 'apps#collection_activity_stats'
    end

    member do 
      get 'activity_stats'
      post 'copy'
      post 'last_request'
      post 'tags'
      delete 'tags', to: 'apps#remove_tags'
    end

    resource :credentials, only: [:show] do
      put '', action: :update
      patch '', action: :patch
    end

    resource :api_key, only: [:create, :update]
  end


  # Legacy traffic to /webhooks gets routed to /activity_entries
  resources :webhooks, only: [:index, :show, :update, :send, :resend], controller: :activity_entries do
    collection do
      post '', action: :create_from_request
    end

    member do
      post 'send', action: :send_new
      post 'resend'
    end
  end

  resources :activity_entries, only: [:index, :create, :show, :update] do
    collection do
      post '', action: :create_from_request
      get 'stats'
      get 'columns'
      get 'keys'
      post 'keys', action: :refresh_keys
      post 'search'
      put 'rerun'
    end

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

  resources :registers, only: [:index, :show, :create, :update]
  resources :register_items, only: [:index, :show, :create, :update] do
    collection do
      post 'bulk_create'
      get 'columns'
      get 'sum'
    end
  end

  resources :dashboards do
    resources :charts
  end

  post 'reports/:report_name', to: 'reports#show'

  get 'credential_sets', to: 'credential_sets#index'
  post 'credential_sets', to: 'credential_sets#create'
  get 'credential_sets/:id', to: 'credential_sets#show'
  put 'credential_sets/:id', to: 'credential_sets#update'
  patch 'credential_sets/:id', to: 'credential_sets#patch'
  delete 'credential_sets/:id', to: 'credential_sets#destroy'
  put 'credential_sets/:id/api_key', to: 'credential_sets#update_api_key'

  get '/users/:user_id/permissions', to: 'permissions#show_user'
  get '/:permissible_type/:permissible_id/permissions', to: 'permissions#show_resource'
  post '/:permissible_type/:permissible_id/permission/:permit/users/:user_id', to: 'permissions#grant'
  post '/:permissible_type/:permissible_id/permissions/users/:user_id', to: 'permissions#grant_all'
  delete '/:permissible_type/:permissible_id/permission/:permit/users/:user_id', to: 'permissions#revoke'
  delete '/:permissible_type/:permissible_id/permissions/users/:user_id', to: 'permissions#revoke_all'
  put '/:permissible_type/:permissible_id/transfer/:new_owner_type/:new_owner_id', to: 'permissions#transfer'

  get '/up', to: 'health_check#show'
end
