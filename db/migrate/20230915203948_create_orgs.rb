class CreateOrgs < ActiveRecord::Migration[7.0]
  def change
    create_table :orgs do |t|

      t.timestamps
    end
  end
end
