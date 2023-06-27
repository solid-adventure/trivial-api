require 'digest/sha1'
include DatastoreManager

class DatastoreController < ApplicationController
    skip_before_action :authenticate_user!
    before_action :authenticate_app!

    def show
        puts 'show'
    end

    def create_account
        user = User.find(current_app[:user_id])
        if user.customers.length == 0
            raise 'User account must be associated with customer'
        end
        customer = user.customers.first
        DatastoreManager.create_datastore_account_for_customer(user, customer)
    end

    def verify_model
        customer = DatastoreManager.get_customer(current_app, params)

        table_updates = DatastoreManager.verify_model(
            JSON.parse(params[:records].to_json),
            params[:table_name].to_s.downcase,
            JSON.parse(params[:unique_keys].to_json),
            JSON.parse(params[:nested_tables].to_json),
            customer.username,
            customer.id,
            'customer',
            params.fetch(:apply_table_changes, false))
        render json: {table_updates: table_updates}
    end

    def insert_values
        customer = DatastoreManager.get_customer(current_app, params)

        records_inserted = DatastoreManager.insert_records(
            JSON.parse(params[:records].to_json),
            params[:table_name].to_s.downcase,
            JSON.parse(params[:unique_keys].to_json),
            JSON.parse(params[:nested_tables].to_json),
            customer.username,
            customer.id,
            'customer',
            params.fetch(:apply_table_changes, false))
        render json: {records_inserted: records_inserted}
    end
end
