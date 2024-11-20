# app/models/owned_audit.rb

class OwnedAudit < Audited::Audit
  belongs_to :owner, polymorphic: true, optional: true
end
