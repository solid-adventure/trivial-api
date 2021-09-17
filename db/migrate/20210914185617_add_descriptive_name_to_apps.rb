class AddDescriptiveNameToApps < ActiveRecord::Migration[6.0]
  def change
    add_column :apps, :descriptive_name, :string
    App.all.each do |r|
      r.update_attribute(:descriptive_name, r.name)
    end
  end
end
