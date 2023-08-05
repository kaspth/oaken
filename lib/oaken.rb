# frozen_string_literal: true

require_relative "oaken/version"

module Oaken
  class Error < StandardError; end

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
        @type.create!(id: id.hash, **attributes)
      end
    end
  end

  module Data
    extend self

    class Provider < Struct.new(:data, :provider)
      def register(key, type)
        stored = provider.new(type) and data.define_method(key) { stored }
      end
    end

    def self.provider(name, provider)
      define_singleton_method(name) { (@providers ||= {})[name] ||= Provider.new(self, provider) }
      class_eval "def #{name}; self.class.#{name}; end"
    end

    provider :memory, Stored::Memory
    provider :records, Stored::ActiveRecord
  end
end
