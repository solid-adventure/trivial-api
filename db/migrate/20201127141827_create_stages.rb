# frozen_string_literal: true

class CreateStages < ActiveRecord::Migration[6.0]
  def change
    create_table :stages do |t|
      t.references  :flow
      t.string      :name, null: false, default: ''
      t.text        :subcomponents

      t.timestamps
    end
  end
end
