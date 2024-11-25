# lib/audited/auditor_extension.rb

module Audited
  module Auditor
    module ClassMethodsExtension
      def has_owned_audits
        has_many :owned_audits, as: :owner, class_name: Audited.audit_class.name
      end
    end

    module AuditedInstanceMethodsExtension
      def all_audits
        Audited.audit_class
          .where(auditable: self)
          .or(Audited.audit_class.where(associated: self))
          .or(Audited.audit_class.where(owner: self))
          .order(created_at: :desc)
      end

      protected

      def write_audit(attrs)
        if audited_options[:owned_audits]
          attrs[:owner] = if audit_associated_with.nil?
                            send(:owner)
                          else
                            parent = send(audit_associated_with)
                            parent.send(:owner)
                          end
        end
        super
      end
    end
  end
end
