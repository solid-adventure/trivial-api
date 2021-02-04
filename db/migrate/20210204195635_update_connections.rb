class UpdateConnections < ActiveRecord::Migration[6.0]
  def change
    remove_reference :connections, :from
    remove_reference :connections, :to
    add_column :connections, :from_stage_id, :integer
    add_column :connections, :to_stage_id, :integer
    add_column :connections, :from, :string
    add_column :connections, :to, :string

    Rake::Task['tasks:import_from_to'].invoke unless reverting?
  end
end
