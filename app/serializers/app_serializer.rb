class AppSerializer < ActiveModel::Serializer

  include Rails.application.routes.url_helpers

  attributes  :id, :name, :descriptive_name, :hostname, :domain, :load_balancer, :panels, :readable_by,
              :schedule, :aws_role, :created_at, :updated_at, :manifest

  attribute :user_permissions, if: :current_user do
    object.permissions.find_by(user: current_user)&.permits
  end

  def current_user
    scope
  end

  def manifest
    return {} if object.manifests.size == 0
    ManifestSerializer.new(object.manifests.first, scope: scope, root: false, event: object)
  rescue => e
    "No manifest for object: #{e}"
  end

end
