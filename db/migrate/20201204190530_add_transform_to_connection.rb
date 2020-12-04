class AddTransformToConnection < ActiveRecord::Migration[6.0]
  def change
    add_column :connections, :transform, :string
  end
end
