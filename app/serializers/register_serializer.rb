class RegisterSerializer < ActiveModel::Serializer
  attributes :id, :name, :owner_type, :owner_id, :sample_type, :units, :meta, :created_at
end
