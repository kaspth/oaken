# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "oaken"

require "minitest/autorun"

class Oaken::Test < Minitest::Test
  include Oaken::Data
end

User = Struct.new(:name, keyword_init: true)
Comment = Struct.new(:name, keyword_init: true)

Oaken::Data.load_from "test/seeds"
