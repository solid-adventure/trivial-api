require "securerandom"
require 'pg'

module DatastoreManager

    def get_connection()
        PG.connect(dbname: ENV['DATASTORE_POSTGRES_DATABASE'], host: ENV['DATASTORE_POSTGRES_HOST'], user: ENV['DATASTORE_POSTGRES_USER'], password: ENV['DATASTORE_POSTGRES_PASSWORD'], port: 5432)
    end

    def schema_name()
        return 'trivial_datastore'
    end

    def execute_datastore_statement(statement)
        puts 'executing sql: ' + statement
        return self.get_connection().exec(statement)
    end
    
    def create_account_statement(username)
        password = SecureRandom.base64(15)
        user_statement = "CREATE USER #{username} WITH PASSWORD '#{password}';"
        user_statement += "\nGRANT CONNECT ON DATABASE \"#{ENV['DATASTORE_POSTGRES_DATABASE']}\" TO #{username};"
        user_statement += "\nGRANT USAGE ON SCHEMA #{schema_name()} TO #{username};"
        user_statement += "\nGRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA #{schema_name()} TO #{username};"
        user_statement += "\nALTER DEFAULT PRIVILEGES IN SCHEMA #{schema_name()} GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO #{username};"
        return user_statement, password
    end

    def create_datastore_account_for_user(user)
        username = user.email.gsub('+', '_').gsub('@', '_').gsub('.', '_')
        account_statement, password = create_account_statement(username)
        credential_set = CredentialSet.create!(name: "TrivialDatastore", user: user, credential_type: "PostgreSQLCredentials")
        credential_set.credentials.user = user
        credential_set.credentials.secret_value = {
          :database => ENV['DATASTORE_POSTGRES_DATABASE'],
          :host => ENV['DATASTORE_POSTGRES_HOST'],
          :password => password,
          :port => 5432,
          :user => username,
        }
        result = self.execute_datastore_statement(account_statement)
        puts result
        puts "Sleeping 5 seconds after creating new aws role"
        sleep 5.0
        credential_set.credentials.save!
        return
    end

    def flatten_hash(hash)
        hash.each_with_object({}) do |(k, v), h|
            if v.is_a? Hash
                flatten_hash(v).map do |h_k, h_v|
                    h["#{k.downcase}_#{h_k.downcase}"] = h_v
                end
            else 
                h[k.downcase] = v
            end
        end
    end

    def prepare_values(values, tenant_name, tenant_id, tenant_type, unique_keys)
        values.each do |(value)|
            value['tenant_name'] = tenant_name
            value['tenant_id'] = tenant_id
            value['tenant_type'] = tenant_type
            value['external_id'] = unique_keys.split(',').map do |unique_key| value[unique_key] end.join('_')
        end
        return values
    end


    def generate_insert_sql_statement(table_name, data_list, columns, unique_key)
        columns_str = columns.join(', ')
        values = data_list.map do |data|
          quoted_values = data.values.map do |value|
            val = "'#{value}'"
            if value == 'NULL'
                val = value
            end
            val
          end.join(', ')
          "(#{quoted_values})"
        end.join(', ')
      
        conflict_columns = data_list.first.keys.reject { |column| column == unique_key }.join(', ')
        
        on_conflict_update = conflict_columns.split(', ').map { |column| "\"#{column}\"=EXCLUDED.\"#{column}\"" }.join(', ')
      
        sql_statement = "INSERT INTO #{table_name} (#{columns_str}) VALUES #{values} ON CONFLICT (#{unique_key}) DO UPDATE SET #{on_conflict_update};"
        return sql_statement
    end

    def insert_values(table_name, values, columns,  unique_key)
        if values.length == 0
            return
        end    
        insert_statement = self.generate_insert_sql_statement(table_name, values, columns, unique_key)
        return self.execute_datastore_statement(insert_statement)
    end

    def get_existing_table_columns(table_name)
        res = self.execute_datastore_statement("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '#{table_name}'")
      
        columns = {}
        default_columns = self.get_default_columns()
        res.each do |row|
            if !default_columns.has_key?(row['column_name'])
                columns[row['column_name']] = row['data_type']
            end
        end

        columns.each do |k,v|
            data_type = ''
            if v == 'numeric'
                data_type = "NUMERIC"
            elsif v == 'timestamp without time zone'
                data_type = "TIMESTAMP"
            elsif v == 'text'
                data_type = "TEXT"
            elsif v == 'boolean' 
                data_type = "BOOLEAN"
            elsif v == 'json'
                data_type = "JSON"    
            else
                data_type = "TEXT"
            end
            columns[k] = data_type
        end

        pairs = []
        columns.each do |k,v|
            pairs.push("#{k}:#{v}")
        end    
        pairs.sort()
        table_hash = Digest::SHA1.hexdigest(pairs.join(','))
      
        return columns, pairs, table_hash
    end

    def generate_alter_table_sql_statement(table_name, request_columns, existing_columns, pairs)
        missing_columns = request_columns.reject { |column| existing_columns.include?(column) }
      
        if missing_columns.empty?
          return nil, nil
        end
      
        alter_statements = missing_columns.map do |column,datatype|
          "ADD COLUMN #{column} #{datatype}"
        end.join(', ')

        missing_columns.each do |k,v|
            pairs.push("#{k}:#{v}")
        end
      
        sql_statement = "ALTER TABLE #{table_name} #{alter_statements};"

        pairs.sort()
        table_hash = Digest::SHA1.hexdigest(pairs.join(','))
      
        return sql_statement, table_hash
    end

    def get_default_columns()
        return {
            'record_id' => 'SERIAL PRIMARY KEY',
            'tenant_name' => 'VARCHAR(30)',
            'tenant_id' => 'NUMERIC',
            'tenant_type' => 'VARCHAR(30)',
            'external_id' => 'VARCHAR(255) UNIQUE',
        }
    end

    def get_default_data_columns()
        return ['tenant_name', 'tenant_id', 'tenant_type', 'external_id']
    end

    def verify_model_and_insert_records(records, table_name, unique_keys, tenant_name, tenant_id, tenant_type)
        table_statement, table_hash, full_table_name, values, columns, request_columns = self.create_table_statement_from_json(
            records, table_name)   

        # Check for the table definition hash in the database before trying to create a new table
        table_definition = CustomerTableDefinition.find_by(table_name: full_table_name)

        if not table_definition
            # If table does not already exist we execute the DDL
            self.execute_datastore_statement(table_statement)
            # Insert table definition into the database
            CustomerTableDefinition.create(table_name: full_table_name, table_hash: table_hash)
        elsif table_definition.table_hash != table_hash 
            # Get the existing data model so we can alter with new request columns
            existing_columns, existing_pairs, existing_table_hash = self.get_existing_table_columns(table_name)
            if existing_columns.length >= table_definition.max_columns
                raise "Table #{full_table_name} has hit the max columns limit"
            end

            # Generate the column alter command to prepare the table for new fields
            alter_statement, new_table_hash = self.generate_alter_table_sql_statement(
                full_table_name, request_columns, existing_columns, existing_pairs)
            # Verify the existing table matches what we built using the table definition of column:datatype
            if table_definition.table_hash != existing_table_hash
                raise 'Existing table hash no longer matches table hash in the database'
            end

            # Alter the table and save new table hash
            if !alter_statement.nil?
                self.execute_datastore_statement(alter_statement)
                table_definition.table_hash = new_table_hash
                table_definition.save
            end    
        end    

        # Add default column values to each row
        final_values = self.prepare_values(values, tenant_name, tenant_id, 'member', unique_keys)

        # Batch insert 20 at a time
        final_values.each_slice(20){|group|
            self.insert_values(full_table_name, group, columns, 'external_id')
        }
        return final_values.length
    end

    def create_table_statement_from_json(json_object, table_name)
        # Parse the JSON object
        parsed_objects = JSON.parse(json_object)
        parsed_objects = parsed_objects.map do |(parsed_object)|
            flatten_hash(parsed_object)
        end

        # Create one object with keys from every object to ensure the model can handle all values
        agg_column_mapping = {}
        parsed_objects.each do |(parsed_object)|
            parsed_object.each_with_index do |(key, value), index|
                agg_column_mapping[key] = value
            end  
        end

        # Normalize the data so each object has all the keys
        parsed_objects = parsed_objects.map do |(object)|
            new_object = {}
            agg_column_mapping.each do |(k,v)|
                new_object[k] = object.fetch(k, 'NULL')
            end
            new_object
        end

        # Protect against empty objects
        if agg_column_mapping.keys().length == 0
            raise 'Could not create table for empty object'
        end


        full_table_name = "#{schema_name()}.#{table_name}" 
    
        # Start building the CREATE TABLE statement
        create_table_statement = "CREATE TABLE #{full_table_name} ("

        # Default table columns
        create_table_statement += "record_id SERIAL PRIMARY KEY,"
        create_table_statement += "tenant_name VARCHAR(30),"
        create_table_statement += "tenant_id NUMERIC,"
        create_table_statement += "tenant_type VARCHAR(30),"
        create_table_statement += "external_id VARCHAR(255) UNIQUE,"

        # keep track of the column:datatype pairs we add to the definition
        pairs = []
        request_columns = {}

        # Determine the data type for the column based on the value of the key in the JSON object
        agg_column_mapping.each_with_index do |(key, value), index|
            column_name = key
            # Select the correct column data type for the value of the key
            if value.is_a?(Integer) || value.is_a?(Float)
                data_type = "NUMERIC"
            elsif value.is_a?(String) && (DateTime.parse(value) <= DateTime.now() rescue false)
                data_type = "TIMESTAMP"
            elsif value.is_a?(String)
                data_type = "TEXT"
            elsif value.is_a?(Array)
                data_type = "JSON"    
            elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
                data_type = "BOOLEAN"
            else
                data_type = "TEXT"
            end
    
            # Add the column definition to the CREATE TABLE statement
            create_table_statement += "\"#{key}\" #{data_type}"
        
            # Add a comma after the column definition unless it's the last column
            create_table_statement += "," unless index == agg_column_mapping.keys.length - 1

            # Add pairs to keep track of uniqueness of table
            pairs.push("#{key}:#{data_type}")
            request_columns[key] = data_type
        end
    
        # Finish building the CREATE TABLE statement
        create_table_statement += ");"
        
        # Enable row level security so users can only see their own records
        create_table_statement += "\nALTER TABLE #{full_table_name} ENABLE ROW LEVEL SECURITY;"

        # Enable row level security policy
        create_table_statement += "\nCREATE POLICY customers_policy ON #{full_table_name} USING (tenant_name = current_user);"

        # Check table for uniqueness so we do not create the same table for multiple customers
        # Sort to ensure columns that come in a different key order will still match
        pairs.sort()
        table_hash = Digest::SHA1.hexdigest(pairs.join(','))

        # Add default columns to the columns lists
        columns = agg_column_mapping.keys() + self.get_default_data_columns()

        return create_table_statement, table_hash, full_table_name, parsed_objects, columns, request_columns
    end
end    