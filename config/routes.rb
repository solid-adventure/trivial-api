# frozen_string_literal: true

Rails.application.routes.draw do
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
  resources :organizations do
    member do
      post 'create_org_role'
      put 'update_org_role'
      delete 'delete_org_role'
    end
  end

  resources :apps, only: [:index, :create, :update, :show, :destroy] do

    member do 
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
    collection do
      get 'name_suggestion'
      get 'stats/hourly'
      get 'stats/daily'
      get 'stats/weekly'
    end
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

  resources :activity_entries, only: [:index, :create, :show, :create_from_request, :update] do
    collection do
      get 'stats'
      get 'keys'
      get 'columns'
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
  resources :register_items, only: [:index, :show, :create] do
    collection do
      get 'columns'
    end
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


  #
  # Start Whiplash customizations
  #
  get '/integrations/whiplash/getCustomersById', to: 'integrations/whiplash#get_customers_by_id'
  get '/integrations/whiplash/getCustomersByName', to: 'integrations/whiplash#get_customers_by_name'
  #
  # End Whiplash customizations
  #


end
