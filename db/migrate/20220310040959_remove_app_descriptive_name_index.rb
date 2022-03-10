class RemoveAppDescriptiveNameIndex < ActiveRecord::Migration[6.0]
  def change
    remove_index :apps, name: "index_apps_on_descriptive_name"
  end
end
