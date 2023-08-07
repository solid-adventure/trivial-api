class Permission < ApplicationRecord
  belongs_to :owner, polymorphic: true

  def as_json(options = {})
    super(options.merge(
      methods: [:owner_name, :resource_name],
    ))
  end

  def owner_name
    if owner_type == 'User'
      User.find(owner_id).name
    elsif owner_type == 'Customer'
      Customer.find(owner_id).name
    else
      CustomerRole.find(owner_id).name
    end
  end

  def resource_name
    if resource_type == 'App'
      App.find(resource_id).descriptive_name
    elsif resource_type == 'CredentialSet'
      CredentialSet.find(resource_id).name
    end
  end
end
