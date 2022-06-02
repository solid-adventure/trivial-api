class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :role, :approval, :color_theme, :created_at, :current_customer_token
end
