class AddContentsToBoard < ActiveRecord::Migration[6.0]
  def change
    add_column  :boards, :contents, :text
  end
end
