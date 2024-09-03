class AuditSerializer < ActiveModel::Serializer
  attributes :id, :auditable_id, :auditable_type, :associated_id, :associated_type, :user_id,
    :action, :audited_changes, :version, :remote_address, :created_at
end
