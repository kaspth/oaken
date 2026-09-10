# frozen_string_literal: true

source "https://gem.coop"

# Specify your gem's dependencies in oaken.gemspec
gemspec

gem "rake"
gem "minitest", "< 6"
gem "debug"

gem "nokogiri"

rails_version = ENV.fetch("RAILS_VERSION", "8.0")

rails_constraint = if rails_version == "main"
  {github: "rails/rails"}
else
  "~> #{rails_version}.0"
end

gem "rails", rails_constraint

gem "sqlite3"
gem "sqlite-ulid", require: "sqlite_ulid"

gem "net-pop", github: "ruby/net-pop"
