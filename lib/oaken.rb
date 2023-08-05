# frozen_string_literal: true

require_relative "oaken/version"

module Oaken
  class Error < StandardError; end

  module Data
    extend self

    def self.register(key, type)
      stored = Stored::Memory.new(type) and define_method(key) { stored }
    end
  end

  module Stored; end
  class Stored::Abstract
    def initialize(type)
      @type = type
    end

    def update(id, **attributes)
      self.class.define_method(id) { find(id) }
    end
  end

  class Stored::Memory < Stored::Abstract
    def find(id)
      objects.fetch(id)
    end

    def update(id, **attributes)
      super
      objects[id] = @type.new(**attributes)
    end

    private def objects
      @objects ||= {}
    end
  end

  class Stored::ActiveRecord < Stored::Abstract
    def find(id)
      @type.find(id.hash)
    end

    def update(id, **attributes)
      super

      if record = @type.find_by(id: id.hash)
        record.update!(**attributes)
      else
        @type.create!(**attributes)
      end
    end
  end
end
