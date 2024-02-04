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
      results = RegisterItem.where(owner: args[:owner])
      .between(args[:start_at], args[:end_at])
      results = results.where(register_id: args[:register_ids]) if args[:register_ids]

      # todo: output formatted fot TableView
      {title: "All Items", count: results.limit(limit) }
    end

    private

    def simple_stat_lookup(stat, args)
      return unless stat.in? %w(count sum average)
      results = RegisterItem.where(owner: args[:owner]) # TODO For records owned by orgs, this needs to be more like accessible_by
      .between(args[:start_at], args[:end_at])
      results = results.where(register_id: args[:register_ids]) if args[:register_ids]
      sample = results.first
      validate_single_unit_of_measure(results) or raise "Cannot report on multiple units in the same report. Please filter by registers with the same units."

      if args[:group_by] == "register"
        results = results.group(:register_id).__send__(stat ,:amount)
        results = apply_multiplier(results, sample.multiplier) if stat.in? %w(sum average)
        return {title: "Count by Register", count: collate_register_names(results) }
      end

      return {title: stat.titleize, count: results.__send__(stat ,:amount) * sample.multiplier } if stat.in? %w(sum average)
      return {title: stat.titleize, count: results.__send__(stat ,:amount) } if stat.in? %w(count)
    end

    def validate_single_unit_of_measure(results)
      results.group(:units).size.keys.length == 1
    end

    def apply_multiplier(results, multiplier)
      results.each do |k,v|
        results[k] = v * multiplier
      end
      results
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