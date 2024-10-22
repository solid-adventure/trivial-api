class Manifest < ApplicationRecord
    include Ownable
    include Permissible

    audited associated_with: :app

    validates :app_id, presence: true
    validates :content, presence: true

    belongs_to :app, foreign_key: :internal_app_id, inverse_of: :manifests
    belongs_to :owner, polymorphic: true
    has_many :permissions, as: :permissible
    has_many :permitted_users, through: :permissions, source: :user

    has_one_attached :bundle

    after_save :create_activity_entry

    def copy_to_app!(new_app)
        new_manifest = self.dup
        new_manifest.app_id = new_app.name
        new_manifest.owner = new_app.owner
        new_manifest.internal_app_id = new_app.id
        if new_manifest.content.is_a? String
            new_manifest.content = JSON.parse(new_manifest.content)
        end
        new_manifest.content["app_id"] = new_manifest.app_id
        # Pushing this responsibility to CredentialSet, which would be able to display an error if the new user doesn't have access to the creds 
        # new_manifest.remove_config
        new_manifest.save!
        return new_manifest
    end

    def remove_config
        content = JSON.parse(self.content)
        recursively_remove_config(content)
        self.content = content.to_json
        self.save
    end

    def recursively_remove_config(target)
        target.delete_if do |k, v|
            if k == "config"
                true
            elsif v.is_a?(Hash)
                recursively_remove_config(v)
                false
            elsif v.is_a?(Array)
                v.map{ |vx| recursively_remove_config(vx)}
                false
            end
        end
    end

    def self.json_patch(new_value={}, old_value={})
        formatted_new_value, formatted_old_value = [new_value, old_value].map do |value|
          parsed = value.is_a?(String) ? JSON.parse(value) : value
          parsed = deep_sort(parsed)
          JSON.pretty_generate(parsed)
        end
        out = Diffy::Diff.new(formatted_new_value, formatted_old_value, context: 4).to_s
        .split("\n").reject { |line| line.strip == '\\ No newline at end of file' }.join("\n")
        out.length > 0 ? strip_left_whitespace(out) : 'Whitespace changes only'
    end

    # Strip indentation on text diffs on pretty JSON when only a section of the file is displayed
    def self.strip_left_whitespace(text)
      lines = text.split("\n")
      min_indent = lines.reject(&:empty?)
                        .map { |line| line.sub(/^[+-]/, '')[/\A\s*/].length }
                        .min || 0
      lines.map do |line|
        if line.start_with?('-', '+')
          "#{line[0]} #{line[1..-1].sub(/^\s{#{min_indent}}/, '')}"
        else
          " #{line.sub(/^\s{#{min_indent}}/, '')}"
        end
      end.join("\n")
    end

    # Alphabetize the keys in the manifest content to avoid whitespace changes
    def self.deep_sort(obj)
      case obj
      when Hash
        obj.sort.to_h.transform_values { |v| deep_sort(v) }
      when Array
        obj.map { |v| deep_sort(v) }
      else
        obj
      end
    end

    private

    def create_activity_entry
        current_audit = audits.last
        entry = ActivityEntry.new
        entry.owner = owner
        entry.app = app
        entry.activity_type = 'build'
        entry.status = '200'
        entry.diagnostics = {
            build_info: {
                audit_id: current_audit.id,
                action: current_audit.action,
                user: current_audit.user_id
            }
        }
        entry.save!
    end
end
