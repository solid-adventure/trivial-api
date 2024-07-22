class DashboardSerializer < ActiveModel::Serializer
  attributes :id, :owner_type, :owner_id, :name, :dashboard_type
  has_many :charts
end
