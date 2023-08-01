# frozen_string_literal: true

require_relative "oaken/version"

module Oaken
  class Error < StandardError; end

  module Tables
    def users
      Table.new(:users)
    end
  end

  class Table
    def initialize(name)
      @name = name
    end

    def update(name, **attributes)
      if record = @records.find_by(id: name.hash)
        record.update! **attributes
      else
        @records.create!(attributes)
      end
    end
  end
end
