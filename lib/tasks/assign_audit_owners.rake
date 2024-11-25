# Usage rake assign_audit_owners:run

namespace :assign_audit_owners do
  desc "Fill empty owners for audits where possible"
  task run: :environment do
    puts 'Starting task "assign_audit_owners"'

    ownerless_audits = OwnedAudit.where(owner: nil)
    ownerless_audits_count = ownerless_audits.size
    update_count = 0
    ownerless_audits.find_in_batches(batch_size: 1000) do |audits_batch|
      audit_updates = audits_batch.map do |audit|
        if audit.auditable&.respond_to?(:owner)
          { id: audit.id, owner_id: audit.auditable.owner_id, owner_type: audit.auditable.owner_type }
        elsif audit.associated&.respond_to?(:owner)
          { id: audit.id, owner_id: audit.associated.owner_id, owner_type: audit.associated.owner_type }
        end
      end.compact

      OwnedAudit.upsert_all(audit_updates, unique_by: :id) if audit_updates.any?
      update_count += audit_updates.size
      puts "[assign_audit_owners] updated #{update_count} of #{ownerless_audits_count} records"
    end

    puts "[assign_audit_owners] #{ownerless_audits_count - update_count} records did not have a valid owner to assign"
    puts 'Task "assign_audit_owners" complete'
  end
end
