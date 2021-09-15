class AddAwsRoleToUsers < ActiveRecord::Migration[6.0]
  class User < ActiveRecord::Base
  end

  def up
    add_column :users, :aws_role, :string
    User.where(aws_role: nil).update_all(aws_role: 'arn:aws:iam::404573752214:role/lambda-ex')
  end

  def down
    remove_column :users, :aws_role, :string
  end
end
