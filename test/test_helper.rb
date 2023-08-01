# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "oaken"

require "minitest/autorun"

class Oaken::Test < Minitest::Test
  include Oaken::Tables
end

Oaken::Tables.seeds do
  users.update :kasper, name: "Kasper"
end
