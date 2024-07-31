class OrganizationSerializer < ActiveModel::Serializer
  attributes :id, :name, :billing_email
  has_many :org_roles, key: :users, if: -> { instance_options[:include_users] }
  has_many :owned_dashboards, key: :dashboards

  class OrgRoleSerializer < ActiveModel::Serializer
    attributes :id, :name, :email, :role

    def id
      object.user.id
    end

    def name
      object.user.name
    end

    def email
      object.user.email
    end
  end

  class DashboardSerializer < ActiveModel::Serializer
    attributes :id, :name
  end
end
