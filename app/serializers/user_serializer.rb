class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :role, :approval, :color_theme

  belongs_to :team
end
