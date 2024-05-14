module Search
  def self.included(base)
    base.extend(ClassMethods)
  end

  JSONB_OPERATORS = %w[? ?& ?| @> @? @@]
  COMPERATORS = %w[< > <= >= = <> !=]
  PREDICATES = ['IS NULL','IS NOT NULL','IS TRUE','IS NOT TRUE','IS FALSE','IS NOT FALSE']
  ORDERINGS = ['ASC', 'DESC', 'ASC NULLS FIRST', 'DESC NULLS FIRST', 'ASC NULLS LAST', 'DESC NULLS LAST']

  class InvalidColumnError < StandardError
    def initialize(msg = 'Invalid or Empty column')
      super(msg)
    end
  end

  class InvalidOperatorError < StandardError
    def initialize(msg = 'Invalid or Empty operator')
      super(msg)
    end
  end
  
  class InvalidPredicateError < StandardError
    def initialize(msg = 'Invalid or Empty predicate')
      super(msg)
    end
  end

  class InvalidOrderingError < StandardError
    def initialize(msg = 'Invalid or Empty ordering')
      super(msg)
    end
  end

  module ClassMethods
    def create_ordering(column, ordering)
      raise InvalidColumnError unless column_names.include?(column)
      raise InvalidOrderingError unless ORDERINGS.include?(ordering)
      return "#{column} #{ordering}"
    end

    def create_query(column, operator, predicate)
      raise InvalidPredicateError unless predicate
      raise InvalidColumnError unless column_names.include?(column)
      query = "#{column} "
      
      data_type = columns_hash[column].type
      if data_type == :jsonb
        raise InvalidOperatorError unless JSONB_OPERATORS.include?(operator)
        query << "#{operator}"
      else # string, integer, and most other data types will use standard comperators
        if operator.empty? # no operator is necessary for SQL defined predicates
          raise InvalidPredicateError unless PREDICATES.include?(predicate)
        else
          raise InvalidOperatorError unless COMPERATORS.include?(operator)
          query << "#{operator}"
        end
      end
      return sanitize_sql_array(["#{query} ?", predicate])
    end

    def get_keys(relation, col, path)
      return [] unless relation
      raise InvalidColumnError unless valid_jsonb_col?(col)

      if path
        type_query = sanitize_sql_array(["jsonb_typeof(#{col} #> ?)", path])
        type = relation.distinct.pluck(Arel.sql(type_query)).compact.first

        if type == 'object'
          query = "jsonb_object_keys(#{col} #> ?)"
          query = sanitize_sql_array([query, path])
        else 
          return []
        end
      else
        query = "jsonb_object_keys(#{col})"
      end

      return relation.distinct.pluck(Arel.sql(query))
    end

    def get_columns(whitelist)
      return whitelist & column_names
    end

    def valid_jsonb_col?(col)
      return column_names.include?(col) && columns_hash[col].type == :jsonb
    end
  end
end
