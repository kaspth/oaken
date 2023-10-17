# frozen_string_literal: true

require "oaken/version"
require "pathname"
require "yaml"
require "digest/md5"

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
    attr_reader :key, :type
    delegate :entry, to: "::Oaken::Seeds.loader"

    def initialize(key, type)
      @key, @type = key, type
    end

    def find(id)
      @type.find id
    end

    def create(reader = nil, **attributes)
      @type.create!(**attributes).tap do |record|
        define_reader reader, record.id if reader
      end
    end

    def insert(reader = nil, **attributes)
      @type.new(attributes).validate!
      @type.insert(attributes).tap do
        define_reader reader, @type.where(attributes).pick(:id) if reader
      end
    end

    def define_reader(name, id)
      entry.define_reader(self, name, id)
    end
  end

  class Loader
    attr_reader :entry

    def initialize(seeds, directories)
      @entry = nil
      @seeds = seeds
      @entry_points = directories.to_h { [ _1, Entry.within(_1) ] }
    end

    def load_each
      @entry_points.each_value do |entries|
        entries.each do |entry|
          @entry = entry
          entry.load_onto @seeds
        end
      end
    end

    class Entry
      def self.within(directory)
        Pathname.glob("#{directory}{,/**/*}.rb").sort.map { new _1 }
      end

      def initialize(pathname)
        @file, @pathname = pathname.to_s, pathname
      end

      def load_onto(seeds)
        seeds.class_eval @pathname.read, @file
      end

      def define_reader(stored, name, id)
        stored.instance_eval "def #{name}() = find #{id}", @file, lineno
      end

      def lineno
        caller_locations(3, 10).find { _1.path == @file }.lineno
      end
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
      stored = Stored::ActiveRecord.new(key, type)
      define_method(key) { stored }
    end

    singleton_class.attr_reader :loader

    def self.load_from(*directories)
      @loader = Loader.new(self, directories) unless loader_defined_before_entrance = defined?(@loader)
      @loader.load_each
    ensure
      @loader = nil unless loader_defined_before_entrance
    end
  end
end
