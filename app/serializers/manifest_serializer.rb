class ManifestSerializer < ActiveModel::Serializer

  include Rails.application.routes.url_helpers

  attributes :id, :app_id, :bundle_url, :content, :owner_id, :owner_type, :created_at, :updated_at

  def bundle_url
    rails_blob_url(object.bundle, disposition: "attachment")
  rescue => e
    ""
  end

end
