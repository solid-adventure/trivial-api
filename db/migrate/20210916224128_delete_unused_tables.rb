class DeleteUnusedTables < ActiveRecord::Migration[6.0]
  def up
    drop_table :boards
    drop_table :boards_users
    drop_table :connections
    drop_table :flows
    drop_table :stages
    drop_table :teams

  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

end
