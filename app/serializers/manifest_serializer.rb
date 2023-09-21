class ManifestSerializer < ActiveModel::Serializer

  include Rails.application.routes.url_helpers

  attributes :id, :app_id, :bundle_url, :content, :created_at, :updated_at

  attribute :user_permissions, if :current_user do
    object.permissions.find_by(user: current_user)&.permits
  end

  def current_user
    scope
  end

  def bundle_url
    rails_blob_url(object.bundle, disposition: "attachment")
  rescue => e
    ""
  end

end
