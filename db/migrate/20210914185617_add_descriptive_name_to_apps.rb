class AddDescriptiveNameToApps < ActiveRecord::Migration[6.0]
  def change
    add_column :apps, :descriptive_name, :string
  end
end
