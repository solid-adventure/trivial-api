require 'digest/sha1'
include DatastoreManager

class DatastoreController < ApplicationController
    skip_before_action :authenticate_user! 

    def show
        puts 'show'
    end

    def create_user
        username = 'testuser'
        user_statement, password = DatastoreManager.create_account_statement(username)
        puts username, password, user_statement

    end

    def create_model
        table_statement, table_hash, full_table_name = DatastoreManager.create_table_from_json(params[:obj].to_json, params[:table_name].to_s)     
        puts table_statement, table_hash, full_table_name
        table_definition = CustomerTableDefinition.find_by(table_hash: table_hash)
        puts table_definition
        if table_definition
            full_table_name = table_definition.table_name
        else    
            ActiveRecord::Base.connection.execute(table_statement)
            CustomerTableDefinition.create(table_name: full_table_name, table_hash: table_hash)
        end    
        render json: {table_name: full_table_name, table_hash: table_hash}
    end
       
end    