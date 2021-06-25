class Manifest < ApplicationRecord
    validates :app_id, presence: true
    validates :user_id, presence: true
    validates :content, presence: true

    belongs_to :user
    belongs_to :app, foreign_key: :internal_app_id, inverse_of: :manifests

end
