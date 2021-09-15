class App < ApplicationRecord
  include Discard::Model

  MINIMUM_PORT_NUMBER = 3001

  belongs_to :user
  has_many :manifests, foreign_key: :internal_app_id, inverse_of: :app

  validates :name, :port, presence: true, uniqueness: true

  before_validation :set_defaults

  def url
    base = URI(App.base_url)
    base.hostname = "#{hostname}.#{domain}"
    base.to_s
  end

  def aws_role
    user.ensure_aws_role!
  end

  def self.default_domain
    URI(App.base_url).hostname
  end

  def self.default_load_balancer
    ENV['DEFAULT_LOAD_BALANCER'] || 'staging-lb'
  end

  def self.base_url
    ENV['BASE_URL'] || 'https://staging.trivialapps.io'
  end

  private

  def set_defaults
    self.name = random_name unless name.present?
    self.port = next_available_port unless port.present?
    self.hostname = name.to_s.downcase unless hostname.present?
    self.domain = App.default_domain unless domain.present?
    self.load_balancer = App.default_load_balancer unless load_balancer.present?
  end

  def random_name
    Spicy::Proton.pair('_').camelize
  end

  def next_available_port
    App.maximum(:port).try(:next) || MINIMUM_PORT_NUMBER
  end

end
