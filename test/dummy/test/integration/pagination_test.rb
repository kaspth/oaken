require "test_helper"

class PaginationTest < ActiveSupport::TestCase
  seed "cases/pagination"

  test "pagination sorta" do
    assert_operator Order.count, :>=, 100
  end
end
