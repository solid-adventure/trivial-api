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
        .between(args[:start_at], args[:end_at])

      results = results.where(register_id: args[:register_ids]) if args[:register_ids]

      sample = results.first
      validate_single_unit_of_measure(results) or raise "Cannot report on multiple units in the same report. Please filter by registers with the same units."

      if args[:group_by]
        whitelisted_groups = sample.register.meta.values + ["register_id"]
      # NOTE: We accept group_by as an array to support grouping by multiple dimensions later, but for now we only support one dimension
        args[:group_by].map { |i| raise "Invalid group by: #{i} is not a meta key for register" unless i.in? whitelisted_groups }
        meta_groups = args[:group_by].map { |i| RegisterItem.meta_column(i, sample.register.meta) }
        results = results.group(meta_groups).__send__(stat ,:amount)
        results = collate_register_names(results) if meta_groups.include? "register_id"
        return {title: "Count by Register", count: results }
      end

      # return {title: stat.titleize, count: results.__send__(stat ,:amount)  } if stat.in? %w(sum average)
      return {title: stat.titleize, count: results.__send__(stat ,:amount) } #if stat.in? %w(count)
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
