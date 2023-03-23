class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :role, :approval, :color_theme, :created_at, :current_customer_token,
  :account_locked, :account_locked_reason, :trial_expires_at
end
