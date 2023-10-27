class PermissionsData < ActiveRecord::Migration[7.0]
  def up

    # Permit users full control of th their own apps
    User.all.each do |user|
      user.apps.each do |app|
        app.grant_all(user_ids: [user.id])
      end
    end

    # Permit all users in Org to read the orgs apps to mimic pre-permissions behavior
    Organization.all.each do |org|
      org.users.each do |user|
        user.apps.each do |app|
          app.grant(permit: :read, user_ids: org.users.pluck(:id))
        end
      end
    end

  end

  def down
    Permission.delete_all
  end

end



