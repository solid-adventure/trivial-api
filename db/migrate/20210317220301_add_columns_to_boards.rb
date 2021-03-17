class AddColumnsToBoards < ActiveRecord::Migration[6.0]
  def change
    add_column :boards, :meta_description, :string
    add_column :boards, :featured, :boolean
  end
end
