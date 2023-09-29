class OrganizationSerializer < ActiveModel::Serializer
  attributes :id, :name, :token, :billing_email
  has_many :users, through: :org_roles, source: :user
 
  attribute :org_role, if: -> { object.org_role.present? } do
    {
      user_id: object.org_role.user.id,
      role: object.org_role.role
    }
  end
  
  def users
    object.users.map do |user|
      {
        user_id: user.id,
        name: user.name,
        email: user.email,
        role: user.org_roles.find_by(organization_id: object.id).role
      }
    end
  end
end
