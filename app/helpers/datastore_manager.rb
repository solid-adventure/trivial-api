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

    def flatten_hash_and_normalize_columns(hash)
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

    def prepare_records(records, tenant_name, tenant_id, tenant_type, unique_keys)
        records.each do |(record)|
            record['tenant_name'] = tenant_name
            record['tenant_id'] = tenant_id
            record['tenant_type'] = tenant_type
            record['external_id'] = unique_keys.map do |unique_key| record[unique_key] end.join('_')
        end
        return records
    end


    def generate_insert_sql_statement(table_name, data_list, columns, request_columns, unique_key)
        columns_str = columns.join(', ')
        values = data_list.map do |data|
          quoted_values = data.map do |column,value|
            val = "'#{value}'"
            if value == 'NULL'
                val = value
            end 
            if request_columns[column] == 'JSON'
                val = "'#{value.to_json}'"
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

    def insert_values(table_name, values, columns, request_columns, unique_key)
        if values.length == 0
            return
        end    
        insert_statement = self.generate_insert_sql_statement(table_name, values, columns, request_columns, unique_key)
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
            elsif v == 'timestamp with time zone'
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

    def verify_model_and_insert_records(parent_records, parent_table_name, parent_unique_keys, nested_tables, tenant_name, tenant_id, tenant_type)
        # Process the records recursively and return {full_table_name: {table_settings}}
        tables = self.create_table_statement_from_records(parent_records, parent_table_name, nested_tables, parent_unique_keys, {})   

        # Keep track of total records inserted
        records_inserted = 0

        tables.each do |(key, table)|
            table_name = table[:table_name]
            create_table_statement = table[:create_table_statement]
            table_hash = table[:table_hash]
            full_table_name = table[:full_table_name] 
            records = table[:records] 
            columns = table[:columns] 
            request_columns = table[:request_columns]
            unique_keys = table[:unique_keys]    

            # Check for the table definition hash in the database before trying to create a new table
            table_definition = CustomerTableDefinition.find_by(table_name: full_table_name)

            if not table_definition
                # If table does not already exist we execute the DDL
                self.execute_datastore_statement(create_table_statement)
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
            final_values = self.prepare_records(records, tenant_name, tenant_id, 'member', unique_keys)

            # Batch insert 20 at a time
            final_values.each_slice(20){|group|
                self.insert_values(full_table_name, group, columns, request_columns, 'external_id')
            }
            records_inserted += final_values.length
        end
        return records_inserted
    end

    def create_table_statement_from_records(records, table_name, nested_tables, unique_keys, tables)

        records = records.map do |(record)|
            flatten_hash_and_normalize_columns(record)
        end

        # Create one object with keys from every object to ensure the model can handle all values
        agg_column_mapping = {}
        records.each do |(record)|
            record.each_with_index do |(key, value), index|
                agg_column_mapping[key] = value
            end  
        end

        # Normalize the data so each object has all the keys
        records = records.map do |(record)|
            new_object = {}
            agg_column_mapping.each do |(k,v)|
                new_object[k] = record.fetch(k, 'NULL')
            end
            new_object
        end

        # Protect against empty objects
        if agg_column_mapping.keys().length == 0
            raise 'Could not create table for empty object'
        end

        # Check for nested tables in the records
        if !nested_tables.nil?
            nested_tables.each do |(key, settings)|
                # Collect all nested records from each record
                puts 'nested tables settings', settings
                normalized_key = key.downcase
                nested_table_name = "#{table_name}_#{normalized_key}"
                nested_nested_tables = settings.fetch('nested_tables', {})
                nested_unique_keys = settings.fetch('unique_keys', [])
                parent_keys = settings.fetch('parent_keys', []) 
                parent_nested_records = []
                records.each do |(record)|
                    # Get the list of nested reocrds from parent record
                    nested_records = record.fetch(normalized_key)
                    # Remove the key from parent record
                    record.delete(normalized_key)
                    nested_records.each do |nested_record|
                        parent_keys.each do |parent_key|
                            nested_record[parent_key['to']] = record[parent_key['from']]
                        end
                        parent_nested_records.push(nested_record)
                    end    
                end
                # Remove the key from agg mapping
                agg_column_mapping.delete(normalized_key)
                # Call recursively
                self.create_table_statement_from_records(parent_nested_records, nested_table_name, nested_nested_tables, unique_keys, tables)
            end
        end

        # Create the full table name
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
            elsif value.is_a?(String) && (DateTime.iso8601(value) rescue false)
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

        tables[full_table_name] = {
            table_name: table_name,
            create_table_statement: create_table_statement,
            table_hash: table_hash,
            full_table_name: full_table_name,
            records: records,
            columns: columns,
            request_columns: request_columns,
            unique_keys: unique_keys,
        } 

        return tables
    end
end    