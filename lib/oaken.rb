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
  class Stored::Abstract
    def initialize(name, type)
      @name, @type = name, type
    end

    def update(name, **attributes)
      self.class.define_method(name) { find(name) }
    end
  end

  class Stored::Memory < Stored::Abstract
    def find(name)
      objects.fetch(name)
    end

    def update(name, **attributes)
      super
      objects[name] = @type.new(**attributes)
    end

    private def objects
      @objects ||= {}
    end
  end

  class Stored::ActiveRecord < Stored::Abstract
    def find(name)
      @type.find(name.hash)
    end

    def update(name, **attributes)
      super

      if record = @type.find_by(id: name.hash)
        record.update!(**attributes)
      else
        @type.create!(**attributes)
      end
    end
  end
end
