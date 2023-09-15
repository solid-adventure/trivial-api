class CreateOrgRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :org_roles do |t|

      t.timestamps
    end
  end
end
