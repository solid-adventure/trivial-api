class CreateFlowsAndUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :flows_users do |t|
      t.belongs_to :flow
      t.belongs_to :user
    end
  end
end
