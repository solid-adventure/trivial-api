require 'test_helper'

class ConnectionTest < ActiveSupport::TestCase
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
    @connection = Connection.new
    @connection.flow = @flow
    @connection.from = @stage
    @connection.to = @stage2
    @connection.save!
  end

  test "valid connection" do
    assert @connection.valid?
  end

  test "invalid without flow" do
    @connection.flow = nil
    @connection.valid?

    assert_equal @connection.errors[:flow], ["must exist", "can't be blank"]
  end

  test "invalid without from" do
    @connection.from = nil
    @connection.valid?

    assert_equal @connection.errors[:from], ["must exist", "can't be blank"]
  end

  test "invalid without to" do
    @connection.to = nil
    @connection.valid?

    assert_equal @connection.errors[:to], ["must exist", "can't be blank"]
  end

  test "destroy flow will destroy connection" do
    @flow.destroy

    assert_equal Connection.count, 0
  end

  test "destroy from(stage) will destroy connection" do
    @stage.destroy

    assert_equal Connection.count, 0
  end

  test "destroy to(stage) will destroy connection" do
    @stage2.destroy
    
    assert_equal Connection.count, 0
  end
end
