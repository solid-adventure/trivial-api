# spec/lib/search_spec.rb
require 'rails_helper'
require 'search'

RSpec.describe Search do
  class TestModel < ApplicationRecord
    include Search
  end

  before(:all) do
    ActiveRecord::Base.connection.create_table(:test_models) do |t|
      t.string :name
      t.integer :age
      t.decimal :amount
      t.boolean :active
      t.jsonb :content
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.drop_table(:test_models)
  end

  describe 'ClassMethods' do
    let(:model) { TestModel }

    before do
      model.create({ 
        name: 'Bilbo',
        age: 111,
        amount: 123.46,
        active: false,
        content: '{title:"The Hobbit", count:1}'
      })
    end

    describe '.create_query' do
      let(:string_col) { "name" }
      let(:int_col) { "name" }
      let(:jsonb_col) { "content" }
      let(:comperator) { "=" }
      let(:operator) { '@@' }
      let(:str) { model.first.name }
      let(:int) { model.first.age }
      let(:predicate) { "$.title == \"The Hobbit\"" }

      it 'raises an exception for invalid columns' do
        invalid_col = "invalid"
        expect {
          model.create_query(invalid_col, comperator, str)
        }.to raise_error(Search::InvalidColumnError)
      end

      it 'raises an exception for invalid operators on jsonb columns' do
        expect(Search::JSONB_OPERATORS.include?(comperator)).to be false
        expect {
          model.create_query(jsonb_col, comperator, predicate)
        }.to raise_error(Search::InvalidOperatorError)
      end

      it 'raises an exception for invalid comperators on non-jsonb columns' do
        expect(Search::COMPERATORS.include?(operator)).to be false
        expect {
          model.create_query(string_col, operator, str)
        }.to raise_error(Search::InvalidOperatorError)
      end

      it 'raises an exception for empty operators with an invalid predicate' do
        invalid_predicate = "IS A UNICORN"
        expect(Search::PREDICATES.include?(invalid_predicate)).to be false
        expect {
          model.create_query(string_col, '', invalid_predicate)
        }.to raise_error(Search::InvalidPredicateError)
      end

      it 'produces valid Arel.sql strings' do
        string_query = "#{string_col} #{comperator} '#{str}'"
        expect(model.create_query(string_col, comperator, str)).to eq(string_query)

        int_query = "#{int_col} #{comperator} #{int}"
        expect(model.create_query(int_col, comperator, int)).to eq(int_query)

        jsonb_query = "#{jsonb_col} #{operator} '#{predicate}'"
        expect(model.create_query(jsonb_col, operator, predicate)).to eq(jsonb_query)
        
        expect {
          model.where(Arel.sql(string_query))
          model.where(Arel.sql(int_query))
          model.where(Arel.sql(jsonb_query))
        }.not_to raise_error
      end

      it 'handles IN operator with arrays correctly' do
        # Setup additional test data
        model.create(name: 'Frodo', age: 33)
        model.create(name: 'Sam', age: 38)

        values = ['Bilbo', 'Frodo', 'Sam']
        query = model.create_query(string_col, 'IN', values)
        expect(query).to eq("name IN ('Bilbo','Frodo','Sam')")

        # Test actual query execution
        results = model.where(Arel.sql(query))
        expect(results.count).to eq(3)
        expect(results.pluck(:name)).to match_array(['Bilbo', 'Frodo', 'Sam'])

        # Test subset of values
        subset_query = model.create_query(string_col, 'IN', ['Bilbo', 'Frodo'])
        subset_results = model.where(Arel.sql(subset_query))
        expect(subset_results.count).to eq(2)
        expect(subset_results.pluck(:name)).to match_array(['Bilbo', 'Frodo'])

        # Test with non-array predicate
        expect {
          model.create_query(string_col, 'IN', 'not_an_array')
        }.to raise_error(Search::InvalidPredicateError, 'IN operator requires an array')
      end


      it 'sanitizes queries against injection attempts' do
        inject_col = "'; INSERT INTO users (username, password) VALUES ('injected_user', 'password');--"
        expect { model.create_query(inject_col, comperator, str) }.to raise_error(Search::InvalidColumnError)
        
        inject_op = "= '' OR '1'='1;--"
        expect { model.create_query(string_col, inject_op, '') }.to raise_error(Search::InvalidOperatorError)
        
        inject_pred = "'; DROP TABLE test_models;--"
        expect {
          injected_query = model.create_query(string_col, comperator, inject_pred)
          expect(model.where(Arel.sql(injected_query))).to be_empty
          expect(TestModel.count).to eq(1)
        }.not_to raise_error
      end
    end
  end
end
