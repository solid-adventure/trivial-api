# frozen_string_literal: true

class CreateFlows < ActiveRecord::Migration[6.0]
  def change
    create_table :flows do |t|
      t.references  :owner, foreign_key: { to_table: :users }
      t.references  :board
      t.string      :name, null: false, default: ''

      t.timestamps
    end
  end
end
