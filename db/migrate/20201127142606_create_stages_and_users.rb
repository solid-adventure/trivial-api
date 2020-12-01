# frozen_string_literal: true

class CreateStagesAndUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :stages_users do |t|
      t.belongs_to :stage
      t.belongs_to :user
    end
  end
end
