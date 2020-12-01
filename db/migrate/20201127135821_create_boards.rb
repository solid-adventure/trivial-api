# frozen_string_literal: true

class CreateBoards < ActiveRecord::Migration[6.0]
  def change
    create_table :boards do |t|
      t.references  :owner, foreign_key: { to_table: :users }
      t.string      :name,          null: false, default: ''
      t.string      :slug,          null: false, unique: true

      # Public(available to all users, without login)
      # Trivial(available to all logged-in users)
      # Team(available to all members of team)
      # Private(available only to this user)
      t.integer     :access_level,  null: false, default: 0

      t.timestamps
    end
  end
end
