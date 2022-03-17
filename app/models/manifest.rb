class Manifest < ApplicationRecord
    validates :app_id, presence: true
    validates :user_id, presence: true
    validates :content, presence: true

    belongs_to :user
    belongs_to :app, foreign_key: :internal_app_id, inverse_of: :manifests

    def copy_to_app!(new_app)
        new_manifest = self.dup
        new_manifest.app_id = new_app.name
        new_manifest.user_id = new_app.user_id
        new_manifest.internal_app_id = new_app.id
        new_manifest.set_content_app_id
        new_manifest.save!
        return new_manifest
    end

    def set_content_app_id
        content = JSON.parse(self.content)
        content["app_id"] = self.app_id
        self.content = content.to_json
    end

end
