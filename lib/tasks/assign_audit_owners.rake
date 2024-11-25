# Usage rake assign_audit_owners:run

namespace :assign_audit_owners do
  desc "Fill empty owners for audits where possible"
  task run: :environment do
    puts 'Starting task "assign_audit_owners"'

    ownerless_audits = OwnedAudit.where(owner: nil)
    ownerless_audits.find_in_batches(batch_size: 1000) do |audits_batch|
      owner_updates = audits_batch.map do |audit|
        if audit.auditable&.respond_to?(:owner)
          { id: audit.id, owner_id: audit.auditable.owner_id, owner_type: audit.auditable.owner_type }
        elsif audit.associated&.respond_to?(:owner)
          { id: audit.id, owner_id: audit.associated.owner_id, owner_type: audit.associated.owner_type }
        end
      end.compact

      OwnedAudit.upsert_all(updates, unique_by: :id) if owner_updates.any?
    end

    puts 'Task "assign_audit_owners" complete'
  end
end
