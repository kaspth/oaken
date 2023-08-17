# frozen_string_literal: true

require "test_helper"

class OakenTest < Oaken::Test
  class SomeObject; end

  def test_register
    Oaken::Data.memory.register SomeObject
    assert_respond_to self, :oaken_test_some_objects
  end


  def test_that_it_has_a_version_number
    refute_nil ::Oaken::VERSION
  end

  def test_accessing_fixture
    assert_equal "Kasper", users.kasper.name
    assert_equal "Coworker", users.coworker.name

    assert_equal [accounts.business], users.kasper.accounts
    assert_equal [accounts.business], users.coworker.accounts
    assert_equal [users.kasper, users.coworker], accounts.business.users
  end

  def test_default_attributes_override
    assert_equal "Big Business Co.", accounts.business.name
  end

  def test_default_attributes_last_into_test
    users.update :homer
    assert_equal [accounts.business], users.homer.accounts
  end

  def test_default_attributes_block
    users.with accounts: [accounts.update(:home_co)] do
      users.update :homer
    end
    assert_equal [accounts.home_co], users.homer.accounts

    users.update :homer
    assert_equal [accounts.business], users.homer.accounts
  end

  def test_updating_fixture
    users.update :kasper, name: "Kasper2"
    assert_equal "Kasper2", users.kasper.name
  end

  def test_upserting_vs_updating
    assert_equal "Nice!", comments.praise.title

    error = assert_raises RuntimeError do
      comments.update :salty, title: "foo"
    end
    assert_equal "after_create", error.message
  end
end
