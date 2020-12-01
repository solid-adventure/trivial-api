# frozen_string_literal: true

require 'test_helper'

class TeamTest < ActiveSupport::TestCase
  test 'valid team' do
    team = Team.new
    team.name = 'team3'
    assert team.valid?
  end

  test 'invalid without name' do
    team = Team.new
    team.valid?
    assert_equal team.errors.full_messages, ["Name can't be blank", 'Name is too short (minimum is 3 characters)']
  end

  test 'invalid unique name' do
    team = Team.new
    team.name = 'individual'
    team.valid?
    assert_equal team.errors.full_messages, ['Name has already been taken']
  end
end
