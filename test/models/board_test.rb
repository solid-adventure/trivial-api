# frozen_string_literal: true

require 'test_helper'

class BoardTest < ActiveSupport::TestCase
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
  end

  test 'valid board' do
    assert @board.valid?
  end

  test 'invalid without name' do
    @board.name = nil
    @board.valid?

    assert_equal @board.errors[:name], ["can't be blank", 'is too short (minimum is 3 characters)']
  end

  test 'invalid without owner' do
    @board.owner = nil
    @board.valid?

    assert_equal @board.errors[:owner], ['must exist', "can't be blank"]
  end

  test 'invalid without slug' do
    @board.slug = nil
    @board.valid?

    assert_equal @board.errors[:slug], ["can't be blank", 'is too short (minimum is 5 characters)']
  end

  test 'invalid access_level input fails' do
    assert_raises(ArgumentError) do
      @board.access_level = 'abc'
    end
  end

  test 'destroy owner will destroy boards' do
    @user.destroy

    assert_equal Board.count, 0
  end

  test 'add user to board.users will add board to user.boards' do
    @board.users << @user

    assert_equal @user.boards.count, 1
  end

  test 'owner can view secret board' do
    @board.access_level = 'secret'
    @board.save
    assert Board.available(@user).exists?(id: @board.id), 'Secret board owned by user should be available to user, but is not'
  end

  test 'owner can view secret board, regardless of team' do
    @board.access_level = 'secret'
    @board.save
    @user.team = nil
    @user.save
    assert Board.available(@user).exists?(id: @board.id), 'Secret board owned by user should be available to user with no team, but is not'
  end

  test 'guest cannot view secret board' do
    guest = User.create(name: 'test', email: 'test@test.com', password: '12345678')
    @board.access_level = 'secret'
    @board.save
    assert !Board.available(guest).exists?(id: @board.id), 'Secret board not owned by user should not be visible, but is not'
  end


end
