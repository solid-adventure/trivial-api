# app/models/owned_audit.rb

class OwnedAudit < Audited::Audit
  belongs_to :owner, polymorphic: true, optional: true

  delegate :name, :email, to: :user, prefix: true, allow_nil: true
  delegate :reference_name, to: :auditable, allow_nil: true
  alias_attribute :reference_type, :auditable_type
  alias_attribute :reference_id, :auditable_id

  default_scope do
    includes(:user, :auditable)
  end

  def hash_diff(old_value: {}, new_value: {})
    formatted_old_value, formatted_new_value = [old_value, new_value].map do |value|
      parsed = value.is_a?(String) ? JSON.parse(value) : value
      parsed = deep_sort(parsed)
      JSON.pretty_generate(parsed) + "\n"
    end
    diff_text = Diffy::Diff.new(formatted_old_value, formatted_new_value, context: 3).to_s
    diff_text.blank? ? nil : strip_left_whitespace(diff_text)
  end

  private

  def deep_sort(obj)
    case obj
    when Hash
      obj.sort.to_h.transform_values { |v| deep_sort(v) }
    when Array
      obj.map { |v| deep_sort(v) }
    else
      obj
    end
  end

  def strip_left_whitespace(text)
    lines = text.split("\n")
    return text if lines.size < 2

    min_indent = lines.map { |line| line.index(/\S/, 1) }.compact.min

    adjusted_lines = lines.map do |line|
      if line.present? && line.length >= min_indent
        prefix = line[0]
        preserved = line[min_indent..]
        prefix + preserved
      else
        line
      end
    end
    adjusted_lines.join("\n")
  end
end
