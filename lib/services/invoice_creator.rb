module Services
  class InvoiceCreator

    def initialize(register, payee, payor, timezone, start_at, end_at, group_by, group_by_period, search, strategy)
      @register = register
      @payee = payee
      @payor = payor
      @timezone = timezone # Used for group_by_period
      @start_at = start_at
      @end_at = end_at
      @group_by = group_by
      @group_by_period = group_by_period # Currently unused
      @search = search
      @strategy = strategy
      @invoice_ids = []
    end

    def create!
      Rails.logger.info "[InvoiceCreator] started"
      Rails.logger.info "[InvoiceCreator] #{to_invoice.size} register items to invoice"
      if @strategy == "per_customer_id"
        meta_col = meta_columns_from_name(['customer_id']).first
        raise ArgumentError, "Meta column customer_id required for per_customer_id strategy" unless meta_col
        customer_ids = to_invoice.group(meta_col).pluck(meta_col)
        customer_ids.each do |customer_id|
          _create!(customer_id)
        end
      else
        raise ArgumentError, "Invalid strategy: #{@strategy}"
      end
      Rails.logger.info "[InvoiceCreator] finished"
      @invoice_ids
    end


    def _create!(customer_id=nil)
      ActiveRecord::Base.transaction do
        invoice = create_invoice!(customer_id)
        create_invoice_items!(invoice, customer_id)
        assign_register_items(invoice, customer_id)
        @invoice_ids << invoice.id
        commit_transaction = true
        Rails.logger.info "[InvoiceCreator] created invoice #{invoice.id}"
      end
      @invoice_ids
    end

  private

    def create_invoice!(customer_id)
      payor = Organization.find_or_create_by_customer_id(customer_id) if customer_id
      raise "Cannot create invoices without a payor" unless payor || @payor
      Invoice.create!(
        register_id: @register.id,
        date: @end_at,
        currency: @register.units,
        payee_org_id: @payee.id,
        payor_org_id: payor&.id || @payor&.id,
        notes: "#{humanize_date_range(@start_at, @end_at, @timezone)}. Rate price is an average, calculated as Amount % Quantity.",
        owner: @register.owner,
        total: to_invoice(customer_id).sum(:amount)
      )
    end

    def create_invoice_items!(invoice, customer_id)
      to_invoice(customer_id).group(meta_columns_from_name(@group_by))
      .sum(:amount)
      .each do |scope, total|
        next unless total > 0
        Rails.logger.info "[InvoiceCreator] customer_id: #{customer_id}, scope: #{scope}, total: #{total}"
        quantity = sum_item_count(scope, customer_id)
        next unless quantity > 0
        invoice.invoice_items.create!(
          income_account: value_from_group("income_account", scope),
          income_account_group: value_from_group("income_account_group", scope),
          extended_amount: total,
          quantity: quantity,
          unit_price: total.to_f / quantity,
          owner: @register.owner
        )
      rescue => e
        Rails.logger.info "[InvoiceCreator] Error: Unable to create invoice items: #{e}"
        raise e
      end
    end

    def to_invoice(customer_id=nil)
      register_items = @register.register_items
        .where(invoice_id: nil)
        .where(originated_at: @start_at..@end_at)
      if @search.any?
        register_items = RegisterItem.search(register_items, @register.meta, @search)
      end

      if customer_id
        meta_col = meta_columns_from_name(['customer_id']).first
        register_items = register_items.where(meta_col => customer_id)
      end

      register_items
    end

    def sum_item_count(scope, customer_id)
      columns = meta_columns_from_name(@group_by) # meta1, meta5
      conditions = columns.zip(scope).to_h
      item_count_col = meta_columns_from_name(['item_count']).first
      raise "Cannot create invoices without an item_count meta column" unless item_count_col
      to_invoice(customer_id).where(conditions).sum("CAST(#{item_count_col} AS INTEGER)")
    end

    def meta_columns_from_name(column_labels)
      meta = @register.meta.invert
      meta_columns_from_name = column_labels.map do |column|
        meta.fetch(column) { |c| raise ArgumentError, "Invalid column_labels #{c} is not a meta-column for register" }
      end
    end

    def value_from_group(label, scope)
      position = @group_by.index(label)
      return "" unless position
      scope[position] || ""
    end

    def assign_register_items(invoice, customer_id)
      to_invoice(customer_id).update_all(invoice_id: invoice.id)
    end

    def humanize_date_range(start_at, end_at, timezone)
      Time.use_zone(timezone) do
        start_time = Time.zone.parse(start_at)
        end_time = Time.zone.parse(end_at)

        cleaned_timezone = timezone.titleize.gsub('_', ' ')
        "#{start_time.strftime('%B %-d, %Y')} - #{end_time.strftime('%B %-d, %Y')} (#{cleaned_timezone})"
      end
    end


  end
end
