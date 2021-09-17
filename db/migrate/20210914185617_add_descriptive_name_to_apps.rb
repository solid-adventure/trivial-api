class AddDescriptiveNameToApps < ActiveRecord::Migration[6.0]
  class App < ActiveRecord::Base
  end

  def up
    add_column :apps, :descriptive_name, :string

    App.update_all('descriptive_name = name')
    
    change_column_null(:apps, :descriptive_name, false)
  end

  def down
    remove_column :apps, :descriptive_name, :string
  end
end
