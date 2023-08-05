# frozen_string_literal: true

require_relative "oaken/version"

module Oaken
  class Error < StandardError; end

  module Data
    extend self

    def self.register(key, type)
      stored = Stored::Memory.new(key, type) and define_method(key) { stored }
    end
  end

  module Stored; end
  class Stored::Memory
    def initialize(name, type)
      @name, @type = name, type
      @objects = {}
    end

    def update(name, **attributes)
      @objects[name] = @type.new(**attributes)
      self.class.define_method(name) { @objects[name] }

      # if record = @records.find_by(id: name.hash)
      #   record.update! **attributes
      # else
      #   @records.create!(attributes)
      # end
    end
  end
end
