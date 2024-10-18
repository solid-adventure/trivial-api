# To run this file as a standalone test:
# rspec spec/lib/manifest_diff_spec.rb

# manifest_diff_stubs.rb is imported automatically by rails_helper.rb
# methods declared on that modules are available in this file

require 'rails_helper'

RSpec.describe Services::ManifestDiff do

  describe '.main' do

    # TODO test an unchanges manifest

    it 'returns the difference between two hashes' do
      result = described_class.main(simple_content_was, simple_content_is)[0]
      expect(result[:attribute]).to eq('program.definition.actions.0.name')
      expect(result[:humanized_attribute]).to eq('First Action.name')
      expect(result[:new_value]).to eq('"NewNameofAction1"')
      expect(result[:old_value]).to eq('"First Action"')
    end

    it 'returns the difference between two hashes' do
      result = described_class.main(nested_transform_change[0], nested_transform_change[1])
      puts result

    end

  end

  describe '.set_action_names' do
    it 'replaces an action path with a description' do
      result = described_class.main(simple_content_was, simple_content_is)
      hum_result = described_class.set_action_names(result, simple_content_was)
      expect(hum_result[0][:attribute]).to eq('program.definition.actions.0.name')
      expect(hum_result[0][:humanized_attribute]).to eq('First Action.name')
    end
  end

  describe '.extract_definition_actions' do
    it 'handles a simple path' do
      path = "program.definition.actions.0.name"
      expect(described_class.extract_definition_actions(path)).to eq("program.definition.actions.0")
    end

    it 'handles a nested action path' do
      path = "program.definition.actions.0.definition.actions.0.definition.transformations.1.to"
      expect(described_class.extract_definition_actions(path)).to eq("program.definition.actions.0.definition.actions.0")
    end

    it 'maintains a non-zero action location' do
      path = "program.definition.actions.1.definition.actions.0.definition.transformations.1.from"
      expect(described_class.extract_definition_actions(path)).to eq("program.definition.actions.1.definition.actions.0")
    end

  end


  describe '.deep_fetch' do
    it 'handles a simple path' do
      path = "program.definition.actions.0"
      value = described_class.deep_fetch(simple_content_was, path)
      expect(value["name"]).to eq("First Action")
    end

    it 'handles a nested action path' do
      path = "program.definition.actions.0.definition.actions.0"
      value = described_class.deep_fetch(simple_content_was, path)
      expect(value["name"]).to eq("NestedAction1")
    end

    it 'handles a deeply nested transform path' do
      path = "program.definition.actions.1.definition.actions.0.definition.transformations.1"
      value = described_class.deep_fetch(nested_transform_change[0], path)
      expect(value[:to]).to eq("amount")

      path = "program.definition.actions.1"
      value = described_class.deep_fetch(nested_transform_change[0], path)
      expect(value[:name]).to eq("Whiplash/Charge")

      path = "program.definition.actions.1.definition.actions.0.definition"
      value = described_class.deep_fetch(nested_transform_change[0], path)
      puts value
      expect(value[:name]).to eq("Whiplash/Charge")


    end

  end


  describe '.remaining_paths' do
    it 'returns the remaining paths' do
      attribute = "program.definition.actions.0.definition.actions.0.definition.transformations.1.to"
      action_paths = ["definition.actions.0.definition.actions.0"]
      remaining = described_class.remaining_path(attribute, action_paths)
      expect(remaining).to eq("program.definition.transformations.1.to")
    end
  end


end