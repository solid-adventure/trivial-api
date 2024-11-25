# config/initializers/audited.rb
require 'audited/auditor_extension'

Audited.config do |config|
  config.audit_class = "OwnedAudit"
end

module Audited
  module Auditor
    module ClassMethods
      prepend Audited::Auditor::ClassMethodsExtension
    end

    module AuditedInstanceMethods
      prepend Audited::Auditor::AuditedInstanceMethodsExtension
    end
  end
end
