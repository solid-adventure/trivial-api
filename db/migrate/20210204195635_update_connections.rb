class UpdateConnections < ActiveRecord::Migration[6.0]
  def change
    add_column :connections, :from_stage_id, :integer
    add_column :connections, :to_stage_id, :integer
    add_column :connections, :from, :string
    add_column :connections, :to, :string

    unless reverting?
      Rake::Task['tasks:migrate_stages'].invoke
      Rake::Task['tasks:import_from_to'].invoke
    end

    remove_reference :connections, :from
    remove_reference :connections, :to
  end
end
