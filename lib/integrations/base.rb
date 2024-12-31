# lib/integrations/base.rb
module Integrations
  class Base
    # this is an abstract class to provide dynamic integration retrieval
    def initialize
      raise NotImplementedError, "Base is an abstract class and cannot be instantiated directly."
    end
  end
end
