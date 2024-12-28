require 'rails_helper'

RSpec.describe RegisterItem, type: :model do
  describe '.void!' do
    let(:register) { FactoryBot.create :register }
    let!(:original_item) {
      FactoryBot.create(
        :register_item,
        register:,
        amount: 100.0
      )
    }

    context 'when called once' do
      it 'creates a void transaction if it does not exist' do
        expect {
          RegisterItem.void!(RegisterItem.where(register:))
        }.to change { RegisterItem.where(unique_key: "#{original_item.unique_key} - VOID").count }.by(1)

        expect(RegisterItem.sum(:amount)).to eq(0.0)
      end
    end

    context 'when called multiple times' do
      it 'does not create duplicate void transactions' do
        RegisterItem.void!(RegisterItem.where(register:))

        expect {
          RegisterItem.void!(RegisterItem.where(register:))
        }.not_to change { RegisterItem.count }
      end
    end

    context 'when calling void! with a relation containing multiple items' do
      let!(:other_item) {
        FactoryBot.create(
          :register_item,
          register:,
          amount: 12.0
        )
      }
      let!(:other_item_void) {
        FactoryBot.create(
          :register_item,
          register:,
          unique_key: "#{other_item.unique_key} - VOID",
          amount: other_item.amount * -1
        )
      }

      it 'creates void transactions for unpaired items and does not duplicate existing ones' do
        expect(RegisterItem.sum(:amount)).to eq(100.00)

        expect {
          RegisterItem.void!(RegisterItem.where("unique_key ILIKE ?", "#{other_item.unique_key}%"))
        }.not_to change { RegisterItem.count }

        expect {
          RegisterItem.void!(RegisterItem.where(register:))
        }.to change { RegisterItem.count }.by(1)

        expect(RegisterItem.sum(:amount)).to eq(0.0)
      end
    end
  end
end

