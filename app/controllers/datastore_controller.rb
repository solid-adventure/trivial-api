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
            params[:records], 
            params[:table_name], 
            params[:unique_keys], 
            current_user.email, 
            current_user.id, 
            current_user.role)
        render json: {records_inserted: records_inserted}
    end
end    