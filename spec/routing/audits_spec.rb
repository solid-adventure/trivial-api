# spec/routing/audits_spec.rb
require 'rails_helper'

RSpec.describe 'Audits Routing', type: :routing do
  it 'does route to configured paths' do
    expect(get: '/apps/1/audits').to be_routable
    expect(get: '/apps/1/audits/a').to be_routable
  end

  it 'does not route to an invalid path' do
    expect(get: '/activity_entries/1/audits').not_to be_routable
    expect(get: '/activity_entries/1/audits/1').not_to be_routable
  end
end

