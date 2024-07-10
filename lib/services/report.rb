module Services
  class Report
    class ArgumentsError < StandardError; end

    def item_count(args)
      simple_stat_lookup("count", args)
    end

    def item_sum(args)
      simple_stat_lookup("sum", args)
    end

    def item_average(args)
      simple_stat_lookup("average", args)
    end

    def item_list(args)
      raise ArgumentsError, 'Invalid start_at' unless args[:start_at]
      raise ArgumentsError, 'Invalid end_at' unless args[:end_at]
      raise ArgumentsError, 'Invalid register_id' unless args[:register_id]
      limit = args[:limit] || 50

      results = args[:user].associated_register_items
        .where(register_id: args[:register_id])
        .between(args[:start_at], args[:end_at])

      # TODO: output formatted fot TableView
      {title: "All Items", count: results.limit(limit) }
    end

    private

    def simple_stat_lookup(stat, args)
      return unless stat.in? %w(count sum average)
      raise ArgumentsError, 'Invalid start_at' unless args[:start_at]
      raise ArgumentsError, 'Invalid end_at' unless args[:end_at]
      raise ArgumentsError, 'Invalid register_id' unless register = Register.find_by(id: args[:register_id])
      period_groups_present = args[:group_by_period].present? && args[:timezone].present?
      column_groups_present = args[:group_by].present?

      results = args[:user].associated_register_items
        .where(register_id: register.id)

      if period_groups_present
        results = group_by_period(results, *formatted_group_by_period_args(args))
      else
        results = results.between(args[:start_at], args[:end_at])
      end

      # WARNING: group_by is accepted as an array, but multidimensional grouping is not yet supported
      if column_groups_present
        raise ArgumentsError, 'grouping by multiple dimensions is not yet supported' if args[:group_by].length > 1
        meta = register.meta.invert
        meta_groups = args[:group_by].map do |column|
          meta.fetch(column) { |c| raise ArgumentsError, "Invalid group_by, #{c} is not a meta-column for register" }
        end
        results = results.group(meta_groups)
      end
      title = if period_groups_present && column_groups_present
                "#{ stat.titleize } by #{ args[:group_by_period].titleize } and #{ args[:group_by][0].titleize }"
              elsif period_groups_present
                "#{ stat.titleize } by #{ args[:group_by_period].titleize }"
              elsif column_groups_present
                "#{ stat.titleize } by #{ args[:group_by][0].titleize }"
              else
                stat.titleize
              end

      results = results.__send__(stat ,:amount)
      results = format(results, period_groups_present, column_groups_present)
      return { title: title, count: results }
    end

    # Given an object with an array for a key like: {["Jan 2024", "b2b shipping"]=>0} OR {"b2b shipping"=>0}
    # returns an array of objects with string for keys: [{:period=>"Jan 2024", :group=>"b2b shipping", :value=>0}]
    def format(results, period_groups_present, column_groups_present)
      return [{ period: "All", group: "All", value: results }] if results.is_a? Numeric
      raise "Malformed results for report: #{results}" unless results.is_a? Hash

      # NOTE: .group() always orders the the key array for multidimensional groups by the order they were called in
      # therefor this map implementation relies on calling group by period then group by column on results
      # this ensures period = key[0] and column_group = key[1] in the case that results were grouped by both
      out = results.map do |key, value|
        period, group = if period_groups_present && column_groups_present
                          [key[0], key[1]]
                        elsif period_groups_present
                          [key, 'All']
                        elsif column_groups_present
                          ['All', key]
                        else
                          ['All', 'All'] # this shouldn't be possible
                        end

        {
          period: period,
          group: group,
          value: value
        }
      end
      return quarterize(out)
    end

    # This is a hack to get around the fact that strftime doesn't support quarters
    # We replace "QJan 2024" with "Q1 2024" and so on
    def quarterize(results)
      results.each do |r|
        r[:period] = r[:period]&.gsub(/Q(Jan|Feb|Mar)/, "Q1")&.gsub(/Q(Apr|May|Jun)/, "Q2")&.gsub(/Q(Jul|Aug|Sep)/, "Q3")&.gsub(/Q(Oct|Nov|Dec)/, "Q4")
      end
      return results
    end

    # Given a string in the form "2024-02-14T04:59:59.999Z" and a timezone like "America/Detroit", returns a Time object
    # of Tue, 13 Feb 2024 23:59:59.999000000 EST -05:00
    def time_from_string(time_string, timezone)
      timezone ? Time.find_zone(timezone).parse(time_string) : time_string
    end

    def formatted_group_by_period_args(args)
      [
        args[:group_by_period],
        time_from_string(args[:start_at], args[:timezone]),
        time_from_string(args[:end_at], args[:timezone]),
        args[:timezone]
      ]
    end

    def group_by_period(results, period, start_at, end_at, timezone)
      period&.downcase!
      return results.group_by_day(:originated_at, time_zone: timezone, format: "%b %d %Y", range: start_at..end_at) if period == "day"
      return results.group_by_week(:originated_at, time_zone: timezone, format: "%b %d %Y", range: start_at..end_at) if period == "week"
      return results.group_by_month(:originated_at, time_zone: timezone, format: "%b %Y", range: start_at..end_at) if period == "month"
      return results.group_by_quarter(:originated_at, time_zone: timezone, format: "Q%b %Y", range: start_at..end_at) if period == "quarter"
      return results.group_by_year(:originated_at, time_zone: timezone, format: "%Y", range: start_at..end_at) if period == "year"
      raise ArgumentsError, "Invalid group by period: #{period}"
    end
  end
end
