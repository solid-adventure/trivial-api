class Manifest < ApplicationRecord
    validates :app_id, presence: true
    validates :user_id, presence: true
    validates :content, presence: true

    belongs_to :user

end
