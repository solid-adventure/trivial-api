# frozen_string_literal: true

require 'test_helper'

class FlowTest < ActiveSupport::TestCase
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
    # @flow.owner = @user
    @flow.name = 'flow1'
    @flow.save!
    @board.reload
  end

  test 'valid flow' do
    assert @flow.valid?
  end

  test 'invalid board' do
    @flow.board = nil
    @flow.valid?

    assert_equal @flow.errors[:board], ['must exist', "can't be blank"]
  end

  test 'destroy board will destroy flows' do
    @board.destroy

    assert_equal Flow.count, 0
  end

  test 'destroy owner will destroy flows' do
    @user.destroy

    assert_equal Flow.count, 0
  end


end
