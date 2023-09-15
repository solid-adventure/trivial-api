class AddOwnerToApps < ActiveRecord::Migration[7.0]
  def change
    add_reference :apps, :owner, polymorphic: true, index: true
  end
end
