class CustomerTableDefinition < ApplicationRecord
    after_initialize :init

    def init 
        self.max_columns ||= 50
    end
end
