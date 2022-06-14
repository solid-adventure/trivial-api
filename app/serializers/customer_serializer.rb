class CustomerSerializer < ActiveModel::Serializer
  attributes :id, :name, :token, :billing_email
end
