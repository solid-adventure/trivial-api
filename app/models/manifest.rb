class Manifest < ApplicationRecord
    validates :app_id, presence: true
    validates :content, presence: true
end
