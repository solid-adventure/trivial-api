# frozen_string_literal: true

require 'test_helper'

class StageTest < ActiveSupport::TestCase
  def setup
    @team = Team.new
    @team.name = 'team3'
    @team.save!
    @user = User.new
    @user.name = 'user'
    @user.email = 'user@email.com'
    @user.role = 'member'
    @user.password = '12345678'
    @user.team = @team
    @user.approval = 'approved'
    @user.save!
    @board = Board.new
    @board.name = 'board1'
    @board.owner = @user
    @board.slug = 'abcde12345'
    @board.access_level = 'free'
    @board.save!
    @flow = Flow.new
    @flow.board = @board
    @flow.name = 'flow1'
    @flow.save!
    @stage = Stage.new
    @stage.flow = @flow
    @stage.name = 'stage1'
    @stage.subcomponents = "[{protocol:'html', content: '<div>Hello Stage!</div>'}]"
    @stage.save!
    @stage2 = Stage.new
    @stage2.flow = @flow
    @stage2.name = 'stage2'
    @stage2.subcomponents = "[{protocol:'html', content: '<div>Hello Stage2!</div>'}]"
    @stage2.save!
    @flow.reload
  end

  test 'valid stage' do
    assert @stage.valid?
  end

  test 'invalid flow' do
    @stage.flow = nil
    @stage.valid?

    assert_equal @stage.errors[:flow], ['must exist', "can't be blank"]
  end

  test 'destroy flow will destroy stages' do
    @flow.destroy
    assert_equal @flow.stages.size, 0
  end

  test 'destroy owner will destroy stages' do
    @user.destroy

    assert_equal Stage.count, 0
  end


end
