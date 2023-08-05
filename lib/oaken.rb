# frozen_string_literal: true

require_relative "oaken/version"

module Oaken
  class Error < StandardError; end

  module Data
    extend self

    def users
      @@users ||= Stored::Memory.new(:users)
    end
  end

  module Stored; end
  class Stored::Memory
    def initialize(name)
      @name = name
      @objects = {}
    end

    def update(name, **attributes)
      require "ostruct" # TODO: Remove OpenStruct relatively soon.

      @objects[name] = OpenStruct.new(attributes)
      self.class.define_method(name) { @objects[name] }

      # if record = @records.find_by(id: name.hash)
      #   record.update! **attributes
      # else
      #   @records.create!(attributes)
      # end
    end
  end
end
