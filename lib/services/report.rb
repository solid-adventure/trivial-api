module Services
  class Report

    def item_count(args)
      simple_stat_lookup("count", args)
    end

    def item_sum(args)
      simple_stat_lookup("sum", args)
    end

    def item_average(args)
      simple_stat_lookup("average", args)
    end

    def cache_cutoff(timezone)
      Time.use_zone(timezone) do
        return Time.current.beginning_of_day - 2.days
      end
    end

    def cache_key(stat, args)
      # Normalize args to ensure consistent cache keys, removing empty values
      # and placing into a consistent order
      args_hash = args.is_a?(Hash) ? args : args.to_h
      cleaned_args = args_hash.reject { |_, v| v.nil? || v.to_s.empty? }
      normalized_args = cleaned_args.transform_values(&:to_s)
                                   .sort_by { |k, _| k.to_s }
                                   .to_h
      args_string = normalized_args.map { |k, v| "#{k}:#{v}" }.join('_')
      key = "simple_stat_lookup/#{stat}"
      key += "_#{args_string}" unless args_string.empty?
      key
    end

    private


    # The main entry point for all report queries. This method
    # will check if the end_at time is after the cache cutoff
    # and if so, will combine the cached results with the live db results
    def simple_stat_lookup(stat, args)
      timezone = validate_timezone!(args[:timezone]).freeze
      start_at, end_at = validate_time_range!(args[:start_at], args[:end_at], timezone)
      cutoff = cache_cutoff(timezone)

      if start_at <= cutoff && end_at <= cutoff
        return cached_simple_stat_lookup(stat, args)
      elsif start_at <= cutoff && end_at > cutoff
        cached_result = cached_simple_stat_lookup(stat, args.merge(end_at: cutoff.iso8601))
        live_result = _simple_stat_lookup(stat, args.merge(start_at: cutoff.iso8601))
        return combine_results(cached_result, live_result)
      elsif start_at > cutoff && end_at > cutoff
        return _simple_stat_lookup(stat, args)
      else
        # This case should never happen if the input is validated correctly
        raise ArgumentError, "Invalid time range"
      end
    end

    def cached_simple_stat_lookup(stat, args)
      Rails.cache.fetch(cache_key(stat, args), expires_in: 1.day) do
        _simple_stat_lookup(stat, args)
      end
    end

    def _simple_stat_lookup(stat, args)
      return unless stat.in? %w(count sum average)
      timezone = validate_timezone!(args[:timezone]).freeze
      start_at, end_at = validate_time_range!(args[:start_at], args[:end_at], timezone)
      raise ArgumentError, 'Invalid register_id' unless register = Register.find_by(id: args[:register_id]).freeze

      results = RegisterItem.where(register_id: register.id)

      if args[:group_by_period].present? && args[:group_by_period] != 'all'
        results = group_by_period(results, args[:group_by_period], start_at, end_at, timezone)
      else
        results = results.between(start_at, end_at)
      end

      # NOTE: multidimensional grouping is currently only supported on register meta-columns
      if args[:group_by].present?
        meta = register.meta.invert
        meta_groups = args[:group_by].map do |column|
          meta.fetch(column) { |c| raise ArgumentError, "Invalid group_by, #{c} is not a meta-column for register" }
        end
        results = results.group(meta_groups)
      end
      results = results.__send__(stat ,:amount)
      results = format(results, args[:group_by_period].present?, args[:group_by].present?, args[:invert_sign])

      title = generate_title(stat, args[:group_by_period], args[:group_by])
      return { title: title, count: results }
    end

    def generate_title(stat, period_groups, column_groups)
      if period_groups && column_groups
        "#{ stat.titleize } by #{ period_groups.titleize } and #{ array_to_title(column_groups) }"
      elsif period_groups
        "#{ stat.titleize } by #{ period_groups.titleize }"
      elsif column_groups
        "#{ stat.titleize } by #{ array_to_title(column_groups) }"
      else
        stat.titleize
      end
    end

    def array_to_title(arr)
      arr.map{ |s| s.titleize(keep_id_suffix: true) }.join(', ')
    end

    # Given an object with an array for a key like: {["Jan 2024", "b2b shipping"]=>0} OR {"b2b shipping"=>0}
    # returns an array of objects with string for keys: [{:period=>"Jan 2024", :group=>"b2b shipping", :value=>0}]
    def format(results, period_groups_present, column_groups_present, invert_sign)
      sign_multiplier = invert_sign ? -1 : 1
      return [{ period: "All", group: "All", value: results * sign_multiplier }] if results.is_a? Numeric
      raise "Malformed results for report: #{results}" unless results.is_a? Hash

      # NOTE: .group() always orders the the key array for multidimensional groups by the order they were called in
      # therefor this map implementation relies on calling group by period then group by column on results
      # this ensures period = key[0] and column_groups = key[1...] in the case that results were grouped by both
      results.map do |key, value|
        value ||= 0
        period, group = if period_groups_present && column_groups_present
                          group = key.length == 2 ? key[1] : key[1...]
                          [key[0], group]
                        elsif period_groups_present
                          [key, 'All']
                        elsif column_groups_present
                          ['All', key]
                        else
                          ['All', 'All'] # this shouldn't be possible
                        end
        group = if group.is_a?(Array)
                  group.map { |entry| entry.nil? ? '' : entry }
                else
                  group.nil? ? '' : group
                end
        {
          period: period,
          group: group,
          value: value * sign_multiplier
        }
      end
    end

    # This is a hack to get around the fact that strftime doesn't support quarters
    MONTH_TO_QUARTER = {
      1 => "Q1", 2 => "Q1", 3 => "Q1",
      4 => "Q2", 5 => "Q2", 6 => "Q2",
      7 => "Q3", 8 => "Q3", 9 => "Q3",
      10 => "Q4", 11 => "Q4", 12 => "Q4"
    }.freeze
    QUARTERIZE_PROC = Proc.new do |date|
      quarter = MONTH_TO_QUARTER[date.month]
      "#{quarter} #{date.year}" # "Jan 1, 2024" => "Q1 2024"
    end

    PERIOD_OPTIONS = {
      "day" => { format: "%b %d %Y" },
      "week" => { format: "%b %d %Y" },
      "month" => { format: "%b %Y" },
      "quarter" => { format: QUARTERIZE_PROC },
      "year" => { format: "%Y" }
    }.freeze
    def group_by_period(results, period, start_at, end_at, timezone)
      period.downcase!
      options = PERIOD_OPTIONS[period]

      raise ArgumentError, "Invalid group by period: #{period}" unless options

      results.group_by_period(
        period.to_sym,
        :originated_at,
        time_zone: timezone,
        format: options[:format],
        range: start_at..end_at
      )
    end

    def validate_timezone!(timezone)
      Time.find_zone!(timezone)
    rescue => e
      raise ArgumentError, "Invalid timezone #{timezone}"
    end

    def validate_time_range!(start_at, end_at, timezone)
      start_at = validate_time!(start_at, timezone)
      end_at = validate_time!(end_at, timezone)
      raise ArgumentError, 'start_at must be earlier than end_at' if start_at >= end_at
      [start_at, end_at]
    end

    def validate_time!(time_string, timezone)
      time = Time.iso8601(time_string)
      return time unless timezone
      time
    end

    def combine_results(cached_result, live_result)
      raise "Invalid cached result" unless cached_result.is_a?(Hash)
      raise "Invalid live result" unless live_result.is_a?(Hash)

      combined = { title: cached_result[:title] }
      cached_counts = cached_result[:count] || []
      live_counts = live_result[:count] || []

      all_groups = (cached_counts + live_counts).map { |item| [item[:period], item[:group]] }.uniq

      # Create lookup hashes for faster access
      cached_lookup = cached_counts.each_with_object({}) { |item, hash| hash[[item[:period], item[:group]]] = item[:value] }
      live_lookup = live_counts.each_with_object({}) { |item, hash| hash[[item[:period], item[:group]]] = item[:value] }

      combined[:count] = all_groups.map do |period, group|
        {
          period: period,
          group: group,
          value: (cached_lookup[[period, group]] || 0) + (live_lookup[[period, group]] || 0)
        }
      end

      combined
    end

  end
end
