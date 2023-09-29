class OrganizationSerializer < ActiveModel::Serializer
  attributes :id, :name, :billing_email
  has_many :users, if: -> { instance_options[:include_users] }
 
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
