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

    private

    def simple_stat_lookup(stat, args)
      return unless stat.in? %w(count sum average)
      timezone = validate_timezone!(args[:timezone]).freeze
      start_at, end_at = validate_time_range!(args[:start_at], args[:end_at], timezone)
      raise ArgumentError, 'Invalid register_id' unless register = Register.find_by(id: args[:register_id]).freeze

      results = args[:user].associated_register_items
        .where(register_id: register.id)

      if args[:group_by_period].present?
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
      raise ArgumentError, 'timezone mismatched from time range timezones' if timezone.utc_offset != time.utc_offset
      time
    end
  end
end
