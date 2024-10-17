module Services
  class ManifestDiff

    def self.main(obj_was = {}, obj_is = {})
      obj_was = JSON.parse(obj_was) if obj_was.is_a?(String)
      obj_is = JSON.parse(obj_is) if obj_is.is_a?(String)
      diff = deep_diff(obj_was, obj_is)

      # NOte: There's an argument for using the new object or the old object to create the action names;
      # We're choosing to reference them by the original name, but may revisit.
      set_action_names(diff, obj_was)
    rescue JSON::ParserError => e
      puts "Error parsing JSON: #{e.message}"
      []
    end


    # Converts a path like "program.definition.actions.0.name"
    # into a friendlier "First Action.name"
    def self.set_action_names(diff, content)
      diff.each do |change|
        action_paths = [extract_definition_actions(change[:attribute])].flatten
        action_names = action_paths.map do |path|
          deep_fetch(content, path)['name']
        end
        change[:humanized_attribute] = action_names.is_a?(Array) ? action_names&.join(' > ') : action_names
        change[:humanized_attribute] += remaining_path(change[:attribute], action_paths)
      end
      diff
    end

    def self.remaining_path(attribute, action_paths)
      action_paths.each do |path|
        attribute = attribute.gsub(path, '').gsub('..', '.')
      end
      attribute
    end

    def self.deep_diff(was, is, path = [])
      result = []
      if was.is_a?(Hash) && is.is_a?(Hash)
        keys = (was.keys + is.keys).uniq
        keys.each do |key|
          new_path = path + [key]
          result += deep_diff(was[key], is[key], new_path)
        end
      elsif was.is_a?(Array) && is.is_a?(Array)
        max_length = [was.length, is.length].max
        (0...max_length).each do |i|
          new_path = path + [i]
          result += deep_diff(was[i], is[i], new_path)
        end
      else
        if was != is
          result << {
            attribute: path.join('.'),
            old_value: was.inspect,
            new_value: is.inspect
          }
        end
      end
      result
    end

    def self.extract_definition_actions(input_string)
      parts = input_string.split('.')
      result = ['program']
      parts.each_with_index do |part, index|
        if part == 'definition' && parts[index + 1] == 'actions'
          result << [part, parts[index + 1], parts[index + 2]].join('.')
        end
      end
      result.join('.')
    end

    def self.deep_fetch(obj, path)
      path.to_s.split('.').reduce(obj) do |memo, key|
        if memo.is_a?(Hash) && key =~ /^\d+$/
          memo[key.to_i]
        elsif memo.is_a?(Array) && key =~ /^\d+$/
          memo[key.to_i]
        else
          memo[key.to_s] || memo[key.to_sym]
        end
      end
    rescue NoMethodError, TypeError
      nil
    end

  end
end
