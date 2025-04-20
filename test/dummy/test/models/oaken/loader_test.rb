require "test_helper"

class Oaken::LoaderTest < ActiveSupport::TestCase
  test "attr_readers" do
    assert_equal Pathname("db/seeds"), Oaken.loader.root
    assert_equal [".", "test"], Oaken.loader.subpaths
    assert_equal Oaken::Seeds, Oaken.loader.context
  end

  test "with" do
    context = Module.new
    loader = Oaken.with(root: "test/seeds", subpaths: "cases", context:)
    assert_equal Pathname("test/seeds"), loader.root
    assert_equal [".", "cases"], loader.subpaths
    assert_equal context, loader.context

    # Ensure we don't clobber settings
    assert_equal Pathname("db/seeds"), Oaken.loader.root
    assert_equal [".", "test"], Oaken.loader.subpaths
    assert_equal Oaken::Seeds, Oaken.loader.context
  end

  test "with + defaults don't carry over" do
    loader = Oaken.with.tap { _1.defaults name: "Someone" }
    assert_empty loader.with.defaults
  end

  test "with + locator" do
    locator = Class.new { attr_accessor :located; alias_method :locate, :located= }.new
    Oaken.with(locator:).locate(:accounts)
    assert_equal locator.located, :accounts
  end

  test "with + provider" do
    context = Module.new
    provider = Struct.new(:loader, :type)
    loader = Oaken.with(provider:, context:).tap { _1.register User }

    instance = Class.new.include(loader.context).new
    assert_respond_to instance, :users
    assert_kind_of provider, instance.users
    assert_equal loader, instance.users.loader
    assert_equal User, instance.users.type
  end
end
