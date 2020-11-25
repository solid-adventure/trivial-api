class CreateBoards < ActiveRecord::Migration[6.0]
  def change
    create_table :boards do |t|
      t.references  :owner, foreign_key: { to_table: :users }
      t.string      :name,        null: false, default: ""
      t.string      :url,         null: false, default: ""

      # Global(available to all users, without login)
      # Trivial(available to all logged-in users)
      # Team(available to all members of team)
      # User(available only to this user)
      t.integer     :permission,  null: false, default: 0
    end
  end
end
