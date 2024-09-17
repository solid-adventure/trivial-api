class AddActivityEntriesIndex < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :activity_entries, :created_at,
      algorithm: :concurrently,
      if_not_exists: true
    add_index :activity_entries, :status,
      where: "status != '200'",
      name: 'index_activity_entries_status_excluding_200',
      algorithm: :concurrently,
      if_not_exists: true
  end
end
