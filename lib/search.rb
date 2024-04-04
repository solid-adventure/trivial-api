module Search
  def self.included(base)
    base.extend(ClassMethods)
  end

  JSONB_OPERATORS = %w[? ?& ?| @> @? @@]
  COMPERATORS = %w[< > <= >= = <> !=]
  PREDICATES = ['IS NULL','IS NOT NULL','IS TRUE','IS NOT TRUE','IS FALSE','IS NOT FALSE']

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

  module ClassMethods
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
  end
end