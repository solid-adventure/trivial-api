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
    @flow.owner = @user
    @flow.name = 'flow1'
    @flow.save!
  end

  test 'valid flow' do
    assert @flow.valid?
  end

  test 'invalid board' do
    @flow.board = nil
    @flow.valid?

    assert_equal @flow.errors[:board], ['must exist', "can't be blank"]
  end

  test 'invalid owner' do
    @flow.owner = nil
    @flow.valid?

    assert_equal @flow.errors[:owner], ['must exist', "can't be blank"]
  end

  test 'invalid name' do
    @flow.name = nil
    @flow.valid?

    assert_equal @flow.errors[:name], ["can't be blank", 'is too short (minimum is 3 characters)']
  end

  test 'destroy board will destroy flows' do
    @board.destroy

    assert_equal Flow.count, 0
  end

  test 'destroy owner will destroy flows' do
    @user.destroy

    assert_equal Flow.count, 0
  end

  test 'add user to flow.users will add flow to user.flows' do
    @flow.users << @user

    assert_equal @user.flows.count, 1
  end
end
