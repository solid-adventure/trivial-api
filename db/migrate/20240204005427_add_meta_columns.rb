class AddMetaColumns < ActiveRecord::Migration[7.0]
  def change

    remove_column :register_items, :meta, :jsonb

    add_column :register_items, :meta0, :string
    add_column :register_items, :meta1, :string
    add_column :register_items, :meta2, :string
    add_column :register_items, :meta3, :string
    add_column :register_items, :meta4, :string
    add_column :register_items, :meta5, :string
    add_column :register_items, :meta6, :string
    add_column :register_items, :meta7, :string
    add_column :register_items, :meta8, :string
    add_column :register_items, :meta9, :string

  end
end
