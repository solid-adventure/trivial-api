# spec/lib/tasks/tasks_spec.rb
require 'rails_helper'
require 'rake'

RSpec.describe 'activity_entries:cleanup', type: :task do
  before :all do
    Rake.application = Rake::Application.new
    Rake.application.rake_require('tasks/tasks')
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task['tasks:cleanup_activity_entries'] }
  let(:owner) { FactoryBot.create :organization }
  let(:register) { owner.owned_registers.first }
  let(:app) { FactoryBot.create :app, owner: owner }

  before do
    @old_kept_entry = FactoryBot.create(
      :activity_entry,
      app: app,
      created_at: 8.days.ago,
      register_item: FactoryBot.create(:register_item, register: register)
    )
    @recent_kept_entry = FactoryBot.create(
      :activity_entry,
      app: app,
      register_item: FactoryBot.create(:register_item, register: register)
    )
    @recent_deleteable_entry = FactoryBot.create :activity_entry, app: app
  end

  it 'deletes ActivityEntries with nil register_item_id older than 7 days and not in preview mode' do
    @old_deleteable_entry = FactoryBot.create :activity_entry, app: app, created_at: 8.days.ago

    expect { task.invoke('7', 'false') }.to change { ActivityEntry.count }.by(-1)

    # Ensure only the correct entries were deleted
    expect(ActivityEntry.exists?(@recent_kept_entry.id)).to be true
    expect(ActivityEntry.exists?(@old_kept_entry.id)).to be true
    expect(ActivityEntry.exists?(@recent_deleteable_entry.id)).to be true
    expect(ActivityEntry.exists?(@old_deleteable_entry.id)).to be false
  end

  it 'does nothing if there are no matching ActivityEntries' do
    task.reenable
    expect { task.invoke('7', 'false') }.not_to change { ActivityEntry.count }
  end

  it 'uses preview mode by default' do
    task.reenable
    @old_deleteable_entry = FactoryBot.create :activity_entry, app: app, created_at: 8.days.ago
    expect { task.invoke('7') }.not_to change { ActivityEntry.count }
  end
end
