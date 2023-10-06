class ConvertCustomersToOrgs < ActiveRecord::Migration[7.0]
  def up
    Customer.all.each do |customer|
      org = Organization.create!(
        name: customer.name,
        billing_email: customer.billing_email
      )
      customer.users.each do |user|
        OrgRole.create!(user_id: user.id, organization_id: org.id, role: 'member')
      end
    end
  end

  def down
    OrgRole.delete_all
    Organization.delete_all
  end

end
