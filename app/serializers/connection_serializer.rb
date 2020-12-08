class ConnectionSerializer < ActiveModel::Serializer
  attributes :id, :flow, :from, :to, :transform
end
