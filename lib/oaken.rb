# frozen_string_literal: true

require "oaken/version"
require "pathname"

module Oaken
  class Error < StandardError; end

  autoload :Entry, "oaken/entry"

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

  singleton_class.attr_accessor :store_path
  @store_path = Pathname.new "tmp/oaken/store/#{Rails.env}"

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

    def self.load_from(*paths)
      paths.each do |path|
        load_one path
      end
    end

    def self.load_one(path)
      @loader = Loader.new(path) unless loader_defined_before_entrance = defined?(@loader)
      @loader.load_onto(self)
    ensure
      @loader = nil unless loader_defined_before_entrance
    end
  end

  class Loader
    attr_reader :entry

    def initialize(path)
      @entries, @entry = Entry.within(path), nil
    end

    def load_onto(seeds)
      @entries.each do |entry|
        @entry = entry
        @entry.load_onto seeds
      end
    end
  end
end
