class AddOwnerToAudits < ActiveRecord::Migration[7.0]
  def change
    add_reference :audits, :owner, polymorphic: true, index: true
  end
end
