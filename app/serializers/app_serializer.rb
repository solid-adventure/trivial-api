class AppSerializer < ActiveModel::Serializer

  include Rails.application.routes.url_helpers

  attributes  :id, :name, :descriptive_name, :hostname, :domain, :load_balancer, :panels, :readable_by,
              :schedule, :aws_role, :bundle_url, :created_at, :updated_at

  def bundle_url
    rails_blob_url(object.manifests.first.bundle, disposition: "attachment")
  rescue => e
    ""
  end

end
