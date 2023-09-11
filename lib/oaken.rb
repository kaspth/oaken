# frozen_string_literal: true

require "oaken/version"
require "pathname"

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

    def create(reader = nil, **attributes)
      @type.create!(**attributes).tap do |record|
        add_reader reader, record.id if reader
      end
    end

    def insert(reader = nil, **attributes)
      @type.new(attributes).validate!
      @type.insert(attributes).tap do
        add_reader reader, @type.where(attributes).pick(:id) if reader
      end
    end

    private
      def add_reader(name, id)
        self.class.define_method(name) { find id }
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
      Pathname.glob("#{directory}{,/**/*}.rb").sort.each do |path|
        Path.new(self, path).process
      end
    end
  end

  class Path
    def initialize(context, path)
      @context, @path = context, path
    end

    def process
      @context.class_eval @path.read
    end
  end
end
