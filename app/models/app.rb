class App < ApplicationRecord

  MINIMUM_PORT_NUMBER = 3001

  belongs_to :user
  has_many :manifests, foreign_key: :internal_app_id, inverse_of: :app

  validates :name, :port, presence: true, uniqueness: true

  before_validation :set_defaults

  private

  def set_defaults
    self.name = random_name unless name.present?
    self.port = next_available_port unless port.present?
  end

  def random_name
    Spicy::Proton.pair('_').camelize
  end

  def next_available_port
    App.maximum(:port).try(:next) || MINIMUM_PORT_NUMBER
  end

end
