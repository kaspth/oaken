# frozen_string_literal: true

require "test_helper"

class OakenTest < ActiveSupport::TestCase
  def test_that_it_has_a_version_number
    refute_nil ::Oaken::VERSION
  end
end
