class CreateAppPermits < ActiveRecord::Migration[7.0]
  def change
    create_table :app_permits, id: false do |t|
      t.references :user, foreign_key: true
      t.references :app, foreign_key: true

      t.integer :permit_mask, default: 0

      t.timestamps
    end
  end
end
