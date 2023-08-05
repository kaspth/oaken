# frozen_string_literal: true

require_relative "oaken/version"

module Oaken
  class Error < StandardError; end

  module Data
    extend self

    def users
      @@users ||= Table.new(:users)
    end

    def self.seeds(&block)
      module_eval(&block)
    end
  end

  class Table
    def initialize(name)
      @name = name
      @fixtures = {}
    end

    def update(name, **attributes)
      require "ostruct" # TODO: Remove OpenStruct relatively soon.

      @fixtures[name] = OpenStruct.new(attributes)
      self.class.define_method(name) { @fixtures[name] }

      # if record = @records.find_by(id: name.hash)
      #   record.update! **attributes
      # else
      #   @records.create!(attributes)
      # end
    end
  end
end
