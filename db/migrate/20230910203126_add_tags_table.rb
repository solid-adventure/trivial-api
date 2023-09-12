class AddTagsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :tags do |t|
      t.string :context
      t.string :name
      t.references :taggable, polymorphic: true, index: true
      t.timestamps
    end
  end
end
