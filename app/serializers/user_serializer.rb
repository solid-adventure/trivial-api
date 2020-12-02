class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :role, :approval

  belongs_to :team
end
