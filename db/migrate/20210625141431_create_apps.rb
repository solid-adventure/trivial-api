class CreateApps < ActiveRecord::Migration[6.0]
  class App < ActiveRecord::Base
  end

  class Manifest < ActiveRecord::Base
  end

  def up
    create_table :apps do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.string :name, null: false, index: { unique: true }
      t.integer :port, null: false, index: { unique: true }
      t.timestamps
    end

    # create internal_app_id column
    add_belongs_to(:manifests, :internal_app, foreign_key: { to_table: :apps })

    Manifest.select(:app_id).distinct(true).each do |identifier|
      m = Manifest.where(app_id: identifier.app_id).order(updated_at: :desc).first
      manifest = ActiveSupport::JSON.decode(m.content)

      app = App.create! do |app|
        app.user_id = m.user_id
        app.name = m.app_id
        app.port = manifest['listen_at']['port'].to_i
      end

      Manifest.where(app_id: app.name).update_all(internal_app_id: app.id)
    rescue => e
      puts "Failed to create app entry for #{identifier.app_id}: #{e}"
      puts e.backtrace.join("\n")
    end
  end

  def down
    remove_belongs_to(:manifests, :internal_app)
    drop_table(:apps)
  end
end
