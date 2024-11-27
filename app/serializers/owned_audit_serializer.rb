class OwnedAuditSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :user_name, :user_email, :reference_id, :reference_type, :reference_name, :action, :audited_changes, :created_at

  def user_name
    object.user_name || 'Not provided'
  end

  def user_email
    object.user_email || 'Not provided'
  end

  def reference_name
    object.reference_name || 'Not provided'
  end

  def audited_changes
    object.audited_changes.map do |key, value|
      patch = \
        if object.auditable_type == 'User' && key == 'tokens'
          "Login/Logout"
        else
          case object.action
          when 'create'
            "[created] #{key}: #{value}"
          when 'update'
            if value[0].is_a?(Hash)
              object.hash_diff(new_value: value[0], old_value: value[1]) || "#{key}: Whitespace changes only"
            else
              "- #{key}: #{value[0]}\n+ #{key}: #{value[1]}"
            end
          when 'destroy'
            "[destroyed] #{key}: #{value}"
          end
        end

      old_value, new_value = case object.action
                             when 'create'
                               [nil, value]
                             when 'update'
                               value
                             when 'destroy'
                               [value, nil]
                             end
      {
        attribute: key,
        patch:,
        old_value:,
        new_value:
      }
    end
  end
end
