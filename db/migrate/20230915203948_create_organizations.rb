class CreateOrganizations < ActiveRecord::Migration[7.0]
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :billing_email

      t.string :token

      t.timestamps
    end
  end
end
