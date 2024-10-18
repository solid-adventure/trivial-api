class CreateDashboards < ActiveRecord::Migration[7.0]
  def change
    create_table :dashboards do |t|
      t.references :owner, null: false, polymorphic: true, index: true
      t.string :name, null: false
      t.string :dashboard_type, null: false, default: 'default'

      t.timestamps
    end

    default_dashboards = []
    Organization.pluck(:id, :name).each do |org_id, org_name|
      default_dashboards.push(
        {
          owner_type: 'Organization',
          owner_id: org_id,
          name: "Default Dashboard"
        }
      )
    end
    Dashboard.insert_all(default_dashboards) if default_dashboards.any?
  end
end
