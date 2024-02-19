require 'rails_helper'

RSpec.describe Chart, type: :model do
  let(:chart) { FactoryBot.create :chart }

  describe 'aliased_groups' do
    it 'produces an aliased report_groups hash' do
      expect(chart.aliased_groups).to eq({
        'customer_id' => false,
        'income_account' => false,
        'entity_type' => false,
        'entity_id' => false
      })
    end
  end

  describe 'unaliased_groups' do
    it 'can produce an unaliased report_groups hash' do
      expect(chart.unaliased_groups).to eq({
        'meta0' => false,
        'meta1' => false,
        'meta2' => false,
        'meta3' => false
      })
    end
  end

  describe 'unalias_groups!' do
    it 'de-aliases a valid report_groups hash' do
      report_groups = {
        'income_account' => false,
        'customer_id' => true
      }
      unaliased_groups = chart.unalias_groups!(report_groups)
      expect(unaliased_groups).to eq({ 'meta1' => false, 'meta0' => true })
    end

    it 'raises an error for invalid report_groups' do
      report_groups = {
        'not_a_real_label' => false
      }
      expect do
        chart.unalias_groups!(report_groups)
      end.to raise_error(StandardError)
    end
  end
end
