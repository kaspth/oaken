# frozen_string_literal: true

require "oaken/version"

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

    def preregister(names)
      names.each do |name|
        register name
      end
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
      def register(type, key = nil)
        key ||= type.name.gsub("::", "_").tap(&:downcase!) << "s"
        stored = provider.new(type)
        data.define_method(key) { stored }
      end

      def preregister(names)
        names.each do |name|
          stored = provider.new(name.singularize.classify.constantize)
          data.define_method(name) { stored }
        end
      end
    end

    def self.provider(name, provider)
      define_singleton_method(name) { (@providers ||= {})[name] ||= Provider.new(self, provider) }
    end

    provider :memory, Stored::Memory
    provider :records, Stored::ActiveRecord
    def register(...) = records.register(...) # Set Active Record as the default provider.

    def self.load_from(directory)
      Dir.glob("#{directory}{,/**/*}.rb").sort.each do |file|
        Oaken::Data.class_eval File.read(file)
      end
    end
  end
end
