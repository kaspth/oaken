# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "oaken"

require "minitest/autorun"

class Oaken::Test < Minitest::Test
  include Oaken::Data
end

User = Struct.new(:name, keyword_init: true)
Oaken::Data.memory.register :users, User

Comment = Struct.new(:name, keyword_init: true)
Oaken::Data.records.register :comments, Comment

Oaken::Data.users.update :kasper, name: "Kasper"
