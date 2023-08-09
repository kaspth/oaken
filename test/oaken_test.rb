# frozen_string_literal: true

require "test_helper"

class OakenTest < Oaken::Test
  class SomeObject; end

  def test_register
    Oaken::Data.memory.register SomeObject
    # assert_respond_to self, :oaken_test_some_objects # TODO: Fix camelcased inflections
  end


  def test_that_it_has_a_version_number
    refute_nil ::Oaken::VERSION
  end

  def test_accessing_fixture
    assert_equal "Kasper", users.kasper.name
  end

  def test_updating_fixture
    users.update :kasper, name: "Kasper2"
    assert_equal "Kasper2", users.kasper.name

    users.update :kasper, name: "Kasper" # TODO: Hack to pretend we've got transactional tests working. Remove after we've connected Active Record.
  end
end
