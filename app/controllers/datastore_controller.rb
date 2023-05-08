require 'digest/sha1'
include DatastoreManager

class DatastoreController < ApplicationController
    skip_before_action :authenticate_user! 

    def show
        puts 'show'
    end


    def insert_values
        username = 'testing_user'
        records_inserted = DatastoreManager.verify_model_and_insert_records(
            params[:records].to_json, 
            params[:table_name].to_s, 
            params[:unique_keys].to_s, 
            username, 
            132, 
            'member')
        render json: {records_inserted: records_inserted}
    end
end    