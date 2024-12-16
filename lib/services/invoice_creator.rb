module Services
  class InvoiceCreator

    def initialize(register, payee, payor, timezone, start_at, end_at, group_by, group_by_period, search)
      @register = register
      @payee = payee
      @payor = payor
      @timezone = timezone # Used for group_by_period
      @start_at = start_at
      @end_at = end_at
      @group_by = group_by
      @group_by_period = group_by_period # TODO Should this be one invoice per result, or ?
      @search = search
      @invoice_ids = []
    end

    def create!
      Rails.logger.info "[InvoiceCreator] started"
      Rails.logger.info "[InvoiceCreator] #{to_invoice.size} register items to invoice"
      ActiveRecord::Base.transaction do
        invoice = create_invoice!
        create_invoice_items!(invoice)
        assign_register_items(invoice)
        @invoice_ids << invoice.id
        commit_transaction = true
      Rails.logger.info "[InvoiceCreator] created invoice #{invoice.id}"
      end
      Rails.logger.info "[InvoiceCreator] finished"
      @invoice_ids
    end

  private

    def create_invoice!
      Invoice.create!(
        register_id: @register.id,
        date: @end_at,
        currency: @register.units,
        payee_org_id: @payee.id,
        payor_org_id: @payor.id,
        notes: "#{@start_at} - #{@end_at}, #{@timezone}. Unit price is an average.",
        owner: @register.owner,
        total: to_invoice.sum(:amount),
      )
    end

    def create_invoice_items!(invoice)
      to_invoice.group(meta_columns_from_name(@group_by))
      .sum(:amount)
      .each do |scope, total|
        next unless total > 0
        Rails.logger.info "[InvoiceCreator] scope: #{scope}, total: #{total}"
        quantity = sum_item_count(scope)
        invoice.invoice_items.create!(
          income_account: "", # TODO Implement
          income_account_group: "", # TODO Implement ,
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

    def to_invoice
      register_items = @register.register_items
        .where(invoice_id: nil)
        .where(originated_at: @start_at..@end_at)
      if @search.any?
        register_items = RegisterItem.search(register_items, @register.meta, @search)
      end
      register_items
    end

    def sum_item_count(scope)
      columns = meta_columns_from_name(@group_by) # meta1, meta5
      conditions = columns.zip(scope).to_h
      item_count_col = meta_columns_from_name(['item_count']).first
      raise "Cannot create invoices without an item_count meta column" unless item_count_col
      to_invoice.where(conditions).sum("CAST(#{item_count_col} AS INTEGER)")
    end

    def assign_register_items(invoice)
      to_invoice.update_all(invoice_id: invoice.id)
    end

    def meta_columns_from_name(column_labels)
      meta = @register.meta.invert
      meta_columns_from_name = column_labels.map do |column|
        meta.fetch(column) { |c| raise ArgumentError, "Invalid column_labels #{c} is not a meta-column for register" }
      end
    end

    def safe_meta_columns_from_name(column_labels)
      meta_columns_from_name(column_labels)
    rescue ArgumentError
      return []
    end


  end
end
