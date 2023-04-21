require "securerandom"

module DatastoreManager
    def create_account_statement(username)
        password = SecureRandom.base64(15)
        user_statement = "CREATE USER #{username} WITH PASSWORD '#{password}';"
        user_statement += "\nGRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA customers TO #{username};"
        user_statement += "\nALTER DEFAULT PRIVILEGES IN SCHEMA customers GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO #{username};"
        return user_statement, password
    end

    def create_table_from_json(json_object, table_name)
        # Parse the JSON object
        parsed_object = JSON.parse(json_object)

        full_table_name = "customers.#{table_name}" 
    
        # Start building the CREATE TABLE statement
        create_table_statement = "CREATE TABLE #{full_table_name} ("

        # Default table columns
        create_table_statement += "record_id SERIAL PRIMARY KEY,"
        create_table_statement += "username VARCHAR(30),"
        create_table_statement += "tenant_id NUMERIC,"
        create_table_statement += "tenant_type VARCHAR(30),"
        create_table_statement += "external_id VARCHAR(255),"

        pairs = []
    
        # Determine the data type for the column based on the value of the key in the JSON object
        parsed_object.each_with_index do |(key, value), index|
            column_name = key
            if value.is_a?(Integer) || value.is_a?(Float)
                data_type = "NUMERIC"
            elsif value.is_a?(String) && (DateTime.parse(value) rescue false)
                data_type = "TIMESTAMP"
            elsif value.is_a?(String)
                data_type = "Text"
            elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
                data_type = "BOOLEAN"
            else
                data_type = "TEXT"
            end
    
            # Add the column definition to the CREATE TABLE statement
            create_table_statement += "#{key} #{data_type}"
        
            # Add a comma after the column definition unless it's the last column
            create_table_statement += "," unless index == parsed_object.keys.length - 1

            # Add pairs to keep track of uniqueness of table
            pairs.push("#{key}:#{data_type}")
        end
    
        # Finish building the CREATE TABLE statement
        create_table_statement += ");"
        
        # Enable row level security so users can only see their own records
        create_table_statement += "\nALTER TABLE #{full_table_name} ENABLE ROW LEVEL SECURITY;"

        # Enable row level security policy
        create_table_statement += "\nCREATE POLICY customers_policy ON #{full_table_name} USING (username = current_user);"

        # Check table for uniqueness so we do not create the same table for multiple customers
        # Sort to ensure columns that come in a different key order will still match
        pairs.sort()
        table_hash = Digest::SHA1.hexdigest(pairs.join(','))

        return create_table_statement, table_hash, full_table_name
    end
end    