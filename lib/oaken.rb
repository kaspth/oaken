# frozen_string_literal: true

require "oaken/version"

module Oaken
  class Error < StandardError; end

  class Inflector
    def tableize(string)
      string.gsub(/(?<=[a-z])(?=[A-Z])/, "_").gsub("::", "_").tap(&:downcase!) << "s"
    end

    def classify(string)
      string.chomp("s").gsub(/_([a-z])/) { $1.upcase }.sub(/^\w/, &:upcase)
    end
  end

  singleton_class.attr_accessor :inflector
  @inflector = Inflector.new

  module Stored; end
  class Stored::ActiveRecord
    def initialize(type)
      @type = type
    end

    def find(id)
      @type.find id
    end

    def access(*names, **values)
      positional = names.zip(@type.last(names.size)).to_h

      values.merge(positional).transform_values(&:id).each do |name, id|
        self.class.define_method(name) { find id }
      end
    end

    def create(**attributes)
      @type.create!(**attributes)
    end

    def insert(**attributes)
      @type.new(attributes).validate!
      @type.insert(attributes)
    end
  end

  module Seeds
    extend self

    def self.preregister(names)
      names.each do |name|
        type = Oaken.inflector.classify(name).safe_constantize and register type, name
      end
    end

    def self.register(type, key = Oaken.inflector.tableize(type.name))
      stored = Stored::ActiveRecord.new(type)
      define_method(key) { stored }
    end

    def self.load_from(directory)
      Dir.glob("#{directory}{,/**/*}.rb").sort.each do |file|
        class_eval File.read(file)
      end
    end
  end
end
