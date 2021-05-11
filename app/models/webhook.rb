class Webhook < ApplicationRecord
    validates :app_id, presence: true
    validates :source, presence: true
end
