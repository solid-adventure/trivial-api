class CreateOrgRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :org_roles do |t|
      t.references :user, foreign_key: true
      t.references :organization, foreign_key: true

      t.string :role

      t.timestamps
    end
  end
end
