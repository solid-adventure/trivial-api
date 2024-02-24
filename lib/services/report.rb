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

    def item_list(args)
      limit = args[:limit] || 50

      results = args[:user].associated_register_items
        .between(args[:start_at], args[:end_at])

      results = results.where(register_id: args[:register_ids]) if args[:register_ids]

      # TODO: output formatted fot TableView
      {title: "All Items", count: results.limit(limit) }
    end

    private

    def simple_stat_lookup(stat, args)
      return unless stat.in? %w(count sum average)

      results = args[:user].associated_register_items
      results = results.where(register_id: args[:register_ids]) if args[:register_ids]

      sample = results.first
      validate_single_unit_of_measure(results) or raise "Cannot report on multiple units in the same report"

      if args[:group_by] && sample
      # NOTE: We accept group_by as an array to support grouping by multiple dimensions later, but for now we only support one dimension
        args[:group_by].map { |i| raise "Invalid group by, not a meta key for register" unless i.in? whitelisted_groups(results) }
        meta_groups = args[:group_by].map { |i| RegisterItem.resolved_column(i, sample.register.meta) }
        results = group_by_period(results, *formattated_group_by_period_args(args))
        results = results.group(meta_groups).__send__(stat ,:amount)
        results = collate_register_names(results) if meta_groups.include? "register_id"
        results = format(results)
        return {title: "Count by Register", count: results }
      end

      results = group_by_period(results, *formattated_group_by_period_args(args))
      results = results.__send__(stat ,:amount)
      return {title: stat.titleize, count: format(results) }
    end

    # Given an object with an array for a key like: {["Jan 2024", "b2b shipping"]=>0},
    # OR  {"b2b shipping"=>0}
    # returns an array of objects with string for keys: [{:period=>"Jan 2024", :group=>"b2b shipping", :value=>0}]
    def format(results)
      out = []
      if ((results.is_a? String) || (results.is_a? Numeric))
        return [{:period=>"All", :group=>"", :value=>results}]
      end

      if results&.keys&.first&.is_a? String
        results.each do |r|
          out.push({
            period: "All",
            group: r[0],
            value: r[1]
          })
        end
        return quarterize(out)
      end

      raise "Multiple groups and period groups not yet supported" if results&.keys&.first&.is_a? Array and results.keys.first.length > 2
      results.each do |k| out.push(
          {:period => k[0][0], :group => k[0][1], :value => k[1]}
        )
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
      Time.find_zone(timezone).parse(time_string)
    end

    def formattated_group_by_period_args(args)
      [
        args[:group_by_period],
        time_from_string(args[:start_at], args[:timezone]),
        time_from_string(args[:end_at], args[:timezone]),
        args[:timezone]
      ]
    end

    def group_by_period(results, period, start_at, end_at, timezone)
      period&.downcase!
      return results.group_by_day(:created_at, time_zone: timezone, format: "%b %d %Y", range: start_at..end_at) if period == "day"
      return results.group_by_week(:created_at, time_zone: timezone, format: "%b %d %Y", range: start_at..end_at) if period == "week"
      return results.group_by_month(:created_at, time_zone: timezone, format: "%b %Y", range: start_at..end_at) if period == "month"
      return results.group_by_quarter(:created_at, time_zone: timezone, format: "Q%b %Y", range: start_at..end_at) if period == "quarter"
      return results.group_by_year(:created_at, time_zone: timezone, format: "%Y", range: start_at..end_at) if period == "year"
      return results.between(start_at, end_at) # Pass through unchanged if no period or invalid period is specified. "total" would commonly trigger this edge case.
    end

    def whitelisted_groups(results)
      register_ids = results.group(:register_id).size.keys
      registers = Register.select(:meta).where(id: register_ids)
      registers.each do |r|
        r.meta.each do |key, val|
          raise "Unable to compare registers with different meta keys" unless val == registers.first.meta[key]
        end
      end
      return registers.first.meta.values + ["register_id"]
    end

    def validate_single_unit_of_measure(results)
      results.group(:units).size.keys.length <= 1
    end

    # Given {1=>404, 3=>1, 2=>1} with keys being register_ids, replace the ids with register.name
    def collate_register_names(results)
      out = {}
      registers = Register.where(id: results.keys).pluck(:id, :name)
      results.each do |k,v|
        out[registers.find{|r| r[0] == k}[1]] = v
      end
      return out
    end
  end
end
