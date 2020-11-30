require 'test_helper'

class StageTest < ActiveSupport::TestCase
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
    @user.save!
    @board = Board.new
    @board.name = "board1"
    @board.owner = @user
    @board.slug = "abcde12345"
    @board.access_level = "free"
    @board.save!
    @flow = Flow.new
    @flow.board = @board
    @flow.owner = @user
    @flow.name = "flow1"
    @flow.save!
    @stage = Stage.new
    @stage.owner = @user
    @stage.flow = @flow
    @stage.name = "stage1"
    @stage.subcomponents = "[{protocol:'html', content: '<div>Hello Stage!</div>'}]"
    @stage.save!
    @stage2 = Stage.new
    @stage2.owner = @user
    @stage2.flow = @flow
    @stage2.name = "stage2"
    @stage2.subcomponents = "[{protocol:'html', content: '<div>Hello Stage2!</div>'}]"
    @stage2.save!
  end

  test "valid stage" do
    assert @stage.valid?
  end

  test "invalid owner" do
    @stage.owner = nil
    @stage.valid?

    assert_equal @stage.errors[:owner], ["must exist", "can't be blank"]
  end

  test "invalid flow" do
    @stage.flow = nil
    @stage.valid?

    assert_equal @stage.errors[:flow], ["must exist", "can't be blank"]
  end

  test "invalid name" do
    @stage.name = nil
    @stage.valid?

    assert_equal @stage.errors[:name], ["can't be blank", "is too short (minimum is 3 characters)"]
  end

  test "invalid subcomponents" do
    @stage.subcomponents = nil
    @stage.valid?

    assert_equal @stage.errors[:subcomponents], ["can't be blank"]
  end

  test "destroy flow will destroy stages" do
    @flow.destroy

    assert_equal Stage.count, 0
  end

  test "destroy owner will destroy stages" do
    @user.destroy

    assert_equal Stage.count, 0
  end

  test "add user to stage.users will add stage to user.stages" do
    @stage.users << @user
    
    assert_equal @user.stages.count, 1
  end
end
