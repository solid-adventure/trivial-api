Ransack.configure do |c|
  # Change default search parameter key name.
  c.search_key = :q

  # Raise errors if a query contains an unknown predicate or attribute.
  c.ignore_unknown_conditions = false


end