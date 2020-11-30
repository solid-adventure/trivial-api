require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @team = Team.new
    @team.name = "team3"
    @team.save!
    @user = User.new
    @user.name = "user"
    @user.email = "user@email.com"
    @user.role = "member"
    @user.password = "12345678"
    @user.team = @team
    @user.approval = "approved"
  end

  test "valid user" do
    assert @user.valid?
  end

  test "invalid without password" do
    @user.password = nil
    @user.valid?

    assert_equal @user.errors[:password], ["can't be blank"]
  end

  test "invalid without email" do
    @user.email = nil
    @user.valid?

    assert_equal @user.errors[:email], ["can't be blank"]
  end

  test "invalid without team" do
    @user.team = nil
    @user.valid?

    assert_equal @user.errors[:team], ["must exist", "can't be blank"]
  end

  test "invalid without name" do
    @user.name = nil
    @user.valid?

    assert_equal @user.errors[:name], ["can't be blank", "is too short (minimum is 3 characters)"]
  end

  test "invalid role input fails" do
    assert_raises(ArgumentError) do
      @user.role = "abc"
    end
  end
  
  test "invalid approval input fails" do
    assert_raises(ArgumentError) do
      @user.approval = "abc"
    end
  end

  test "delete team will change user team to individual" do
    @user.save!
    @team.users << @user
    @team.destroy
    assert_equal @user.team.name, 'individual'
  end
end
