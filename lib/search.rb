module Search
  def self.included(base)
    base.extend(ClassMethods)
  end

  JSONB_OPERATORS = %w[? ?& ?| @> @? @@].freeze
  COMPERATORS = %w[< > <= >= = <> != IN].freeze
  PREDICATES = ['IS NULL','IS NOT NULL','IS TRUE','IS NOT TRUE','IS FALSE','IS NOT FALSE'].freeze
  ORDERINGS = ['ASC', 'DESC', 'ASC NULLS FIRST', 'DESC NULLS FIRST', 'ASC NULLS LAST', 'DESC NULLS LAST'].freeze

  class InvalidColumnError < StandardError
    def initialize(msg = 'Invalid or Empty column')
      super(msg)
    end
  end

  class InvalidPathError < StandardError
    def initialize(msg = 'Invalid or Empty scope')
      super(msg)
    end
  end

  class InvalidScopeError < StandardError
    def initialize(msg = 'Invalid or Empty scope')
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
      data_type = columns_hash[column].type
      query = if operator.empty? # no operator is necessary for SQL defined predicates
                raise InvalidPredicateError unless PREDICATES.include?(predicate)
                "#{column} #{predicate}"
              else
                valid_operator = (data_type == :jsonb ? JSONB_OPERATORS : COMPERATORS).include?(operator)
                raise InvalidOperatorError unless valid_operator
                if operator == 'IN'
                  unless predicate.is_a?(Array) && predicate.any?
                    raise InvalidPredicateError, 'IN operator requires a non-empty array'
                  end
                  sanitize_sql_array(["#{column} IN (?)", predicate])
                else
                  sanitize_sql_array(["#{column} #{operator} ?", predicate])
                end
              end
      query
    end

    def get_keys_from_path(col, path, scope)
      raise InvalidColumnError unless valid_jsonb_col? col
      raise InvalidPathError unless valid_jsonb_path? path
      raise InvalidScopeError unless scope.is_a? ActiveRecord::Relation

      path_query = sanitize_sql_array(["#{col} #> ?", path])

      type_query = "jsonb_typeof(#{path_query})"
      type = self.where(Arel.sql("#{path_query} IS NOT NULL"))
        .merge(scope)
        .distinct
        .pick(Arel.sql(type_query))
      return [] unless type == 'object'

      keys_query = "jsonb_object_keys(#{path_query})"
      return self.where(Arel.sql("#{path_query} IS NOT NULL"))
        .merge(scope)
        .distinct
        .pluck(Arel.sql(keys_query))
    end

    def get_columns(whitelist)
      return whitelist & column_names
    end

    def valid_jsonb_col?(col)
      return column_names.include?(col) && columns_hash[col].type == :jsonb
    end

    # path must be a string with form '{key, sub-array index, ..., sub-key}'
    def valid_jsonb_path?(path)
      return false unless path.is_a? String
      path_regex = /^\{(?:\s*\w+\s*(?:,\s*\w+\s*)*)\}$/
      path.match? path_regex
    end
  end
end
