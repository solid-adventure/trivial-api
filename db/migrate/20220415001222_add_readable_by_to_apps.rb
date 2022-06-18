class AddReadableByToApps < ActiveRecord::Migration[6.0]
  def change
    add_column :apps, :readable_by, :string, allow_null: true
  end
end
