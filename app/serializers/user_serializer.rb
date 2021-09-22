class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :role, :approval, :color_theme
end
