class ChangeManifestContentType < ActiveRecord::Migration[7.0]
  def up
    change_column :manifests, :content, :jsonb
  end

  def down
    change_column :manifests, :content, :json
  end
end
