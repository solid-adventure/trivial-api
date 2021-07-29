class AddColorThemeToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :color_theme, :string
  end
end
