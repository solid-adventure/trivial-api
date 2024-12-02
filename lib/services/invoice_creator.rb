module Services
  class InvoiceCreator

    REQUIRED_META_COLUMNS = %w(customer_id warehouse_id income_account income_account_group)

    def initialize(register, customer_id, end_date, period, invoice_groups)
      @register = register
      @customer_id = customer_id
      @end_date = end_date
      @period = period
      @invoice_groups = invoice_groups # [warehouse_id]
    end


    def valid
      missing_columns = REQUIRED_META_COLUMNS - @register.meta.values
      missing_columns.each do |column|
        # puts "[create_invoices] Skipping register, missing meta column: #{column}: #{@register.id}, #{@register.name}"
      end
      return false if missing_columns.any?
      true
    end

    def create!
      return unless valid
      ActiveRecord::Base.transaction do
        puts "[create_invoices] Creating invoices for customer_id: #{@customer_id}"
        timezone = timezone_for_scenario(@invoice_groups[0])
        set_range(timezone)
        to_invoice.group(meta_groups(@invoice_groups))
        .sum(:amount)
        .each do |group_label, total|
          group_filter = Hash[@invoice_groups.zip([group_label])]
          invoice = create_invoice(group_filter, total)
          invoice_items = create_invoice_items(invoice, group_filter)
          assign_register_items(invoice, group_filter)
          puts "[create_invoices] Created invoice: #{invoice.id}, total: #{total}, #{invoice.notes}"
          raise "Invoice items total does not match invoice" unless invoice.total_matches_items_sum
        end
        true # commit transaction
      end
    end

    def create_invoice(group_filter, total)
      puts "[create_invoices] Creating invoice for #{@customer_id}, group_filter: #{group_filter}, total: #{total}"
      Invoice.create!(
        register_id: @register.id,
        date: @end_at,
        currency: "USD",
        payee_org_id: payee.id,
        payor_org_id: payor.id,
        notes: "customer_id: #{@customer_id}, invoice_group: #{group_filter}",
        owner: @register.owner,
        total: total,
      )
    end

    def create_invoice_items(invoice, group_filter)
      puts "[create_invoices] Creating invoice items for invoice: #{invoice.id}, group_filter: #{group_filter}"
      query = to_invoice(group_filter).group(meta_groups(["income_account", "income_account_group"]))
      totals = query.sum(:amount)
      puts "[create_invoices] Creating invoice items for invoice: #{invoice.id}, totals: #{totals}"
      quantities = query.size()
      totals.zip(quantities).map do |total, quantity|
        invoice.invoice_items.create!(
          income_account: total[0][0] || "",
          income_account_group: total[0][1] || "",
          extended_amount: total[1],
          quantity: quantity[1],
          unit_price: total[1].to_f / quantity[1],
          owner: @register.owner,
        )
      end
    end

    def assign_register_items(invoice, group_filter)
      to_invoice(group_filter).update_all(invoice_id: invoice.id)
    end

    def to_invoice(group_filter=nil)
      register_items = @register.register_items
        .where(invoice_id: nil)
        .where(meta_groups(["customer_id"]).first => @customer_id)
        .where(originated_at: @start_at..@end_at)
      register_items = apply_filter(register_items, group_filter) if group_filter
      register_items
    end

    def apply_filter(register_items, group_filter)
      meta_groups(group_filter.keys).each_with_index do |group, index|
        register_items = register_items.where(group => group_filter.values[index])
      end
      register_items
    end

    def payor
      Organization.first # TEMP
    end

    def payee
      @register.owner
    end

    def timezones
      ["America/New_York", "America/Los_Angeles"]
    end

    def set_range(timezone)
      # Calculate date range using end_date as the anchor and period for the duration
      timezone_end = @end_date.in_time_zone(timezone)

      # Use end_date as the end date (including the full day) and calculate start date based on period
      @end_at = timezone_end.end_of_day
      @start_at = case @period
      when 'month'
        @end_at.beginning_of_month
      when 'week'
        @end_at - 1.week
      when 'day'
        @end_at - 1.day
      else
        raise ArgumentError, "Unsupported period: #{@period}"
      end
    end

    def timezone_for_scenario(warehouse_id)
      timezones.first # TEMP
    end


    def meta_groups(column_labels)
      meta = @register.meta.invert
      meta_groups = column_labels.map do |column|
        meta.fetch(column) { |c| raise ArgumentError, "Invalid group_by, #{c} is not a meta-column for register" }
      end
    end

  end
end
