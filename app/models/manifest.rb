class Manifest < ApplicationRecord
    include Ownable
    include Permissible

    audited associated_with: :app

    validates :app_id, presence: true
    validates :content, presence: true

    belongs_to :app, foreign_key: :internal_app_id, inverse_of: :manifests
    belongs_to :owner, polymorphic: true
    has_many :permissions, as: :permissible
    has_many :permitted_users, through: :permissions, source: :user

    has_one_attached :bundle

    def copy_to_app!(new_app)
        new_manifest = self.dup
        new_manifest.app_id = new_app.name
        new_manifest.owner = new_app.owner
        new_manifest.internal_app_id = new_app.id
        new_manifest.set_content_app_id
        # Pushing this responsibility to CredentialSet, which would be able to display an error if the new user doesn't have access to the creds 
        # new_manifest.remove_config
        new_manifest.save!
        return new_manifest
    end

    def set_content_app_id
        content = JSON.parse(self.content)
        content["app_id"] = self.app_id
        self.content = content.to_json
    end

    def remove_config
        content = JSON.parse(self.content)
        recursively_remove_config(content)
        self.content = content.to_json
        self.save
    end

    def recursively_remove_config(target)
        target.delete_if do |k, v|
            if k == "config"
                true
            elsif v.is_a?(Hash)
                recursively_remove_config(v)
                false
            elsif v.is_a?(Array)
                v.map{ |vx| recursively_remove_config(vx)}
                false
            end
        end
    end
end
