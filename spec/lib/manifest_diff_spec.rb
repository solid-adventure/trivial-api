# To run this file as a standalone test:
# rspec spec/lib/manifest_diff_spec.rb

require 'rails_helper'

RSpec.describe Services::ManifestDiff do

  let(:content_was) do
    {
      'program' => {
        'definition' => {
          'actions' => [
            {
              'name' => 'First Action',
              'id' => 1,
              'enabled' => true,
              'definition' => {
                'actions' => [
                  {
                    'name' => 'NestedAction1',
                    'id' => 11,
                    'enabled' => true,
                    'definition' => {
                      'transformations' => [
                        { 'name' => 'Transform1', 'id' => 111 },
                        { 'name' => 'Transform2', 'id' => 112 }
                      ]
                    }
                  }
                ]
              }
            },
            {
              'name' => 'Action2',
              'id' => 2,
              'enabled' => false
            }
          ]
        }
      }
    }
  end

  let(:content_is) do
    {
      'program' => {
        'definition' => {
          'actions' => [
            {
              'name' => 'NewNameofAction1',
              'id' => 1,
              'enabled' => true,
              'definition' => {
                'actions' => [
                  {
                    'name' => 'NestedAction1',
                    'id' => 11,
                    'enabled' => true,
                    'definition' => {
                      'transformations' => [
                        { 'name' => 'Transform1', 'id' => 111 },
                        { 'name' => 'Transform2', 'id' => 112 }
                      ]
                    }
                  }
                ]
              }
            },
            {
              'name' => 'Action2',
              'id' => 2,
              'enabled' => false
            }
          ]
        }
      }
    }
  end


  describe '.main' do

    # TODO test an unchanges manifest


    it 'returns the difference between two hashes' do
      result = described_class.main(content_was, content_is)[0]
      expect(result[:attribute]).to eq('program.definition.actions.0.name')
      expect(result[:humanized_attribute]).to eq('First Action.name')
      expect(result[:new_value]).to eq('"NewNameofAction1"')
      expect(result[:old_value]).to eq('"First Action"')
    end
  end

  describe '.set_action_names' do
    it 'replaces an action path with a description' do
      result = described_class.main(content_was, content_is)
      hum_result = described_class.set_action_names(result, content_was)
      puts hum_result
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
  end


  describe '.deep_fetch' do
    it 'handles a simple path' do
      path = "program.definition.actions.0"
      value = described_class.deep_fetch(content_was, path)
      expect(value["name"]).to eq("First Action")
    end

    it 'handles a nested action path' do
      path = "program.definition.actions.0.definition.actions.0"
      value = described_class.deep_fetch(content_was, path)
      expect(value["name"]).to eq("NestedAction1")
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