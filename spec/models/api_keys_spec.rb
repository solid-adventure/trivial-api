require 'rails_helper'

describe ApiKeys do

  include_context 'jwt'
  include_context 'aws_credentials'

  let(:app) { FactoryBot.create(:app) }

  describe '.issue!' do
    it 'returns a new token' do
      expect(app.api_keys.issue!).to match /^[^.]+\.[^.]+\.[^.]+$/
    end
  end

  describe '.refresh!' do
    let(:old_key)             { app.api_keys.issue! }
    let(:path)                { '1.1' }
    let(:stored_key)          { old_key }
    let(:stored_credentials)  { "{\"1\":{\"1\":\"#{stored_key}\"}}" }
    let(:result)             { app.api_keys.refresh! old_key, path }

    it 'returns a new token' do
      expect(result).to match /^[^.]+\.[^.]+\.[^.]+$/
    end
    
    context 'invoked for a different app' do
      let(:app2) { FactoryBot.create(:app) }

      it 'raises an error' do
        expect{ app2.api_keys.refresh! old_key, path }.to raise_error 'Invalid app id'
      end
    end

    context 'called with an invalid credentials path specifier' do
      let(:path) { 'splice(1, 2)' }

      it 'raises an error' do
        expect{ result }.to raise_error 'Invalid credentials path'
      end
    end

    context 'called with an out of date token' do
      let(:stored_key) { 'x.y.z' }

      it 'raises an error' do
        expect{ result }.to raise_error ApiKeys::OutdatedKeyError
      end
    end

    context 'called with an unsigned or invalid token' do
      let(:old_key) { JWT.encode({app: app.name}, nil, 'none') }

      it 'raises an error' do
        expect{ result }.to raise_error JWT::DecodeError
      end
    end
  end

  describe '#assert_valid!' do
    let(:key) { app.api_keys.issue! }
    let(:result) { ApiKeys.assert_valid!(key) }

    context 'called with a valid key' do
      it 'returns the app identifier' do
        expect(result).to eq app.name
      end
    end

    context 'called with an invalid or expired key' do
      let(:key) { JWT.encode({app: app.name}, nil, 'none') }

      it 'raises an error' do
        expect{ result }.to raise_error JWT::DecodeError
      end
    end
  end

end
