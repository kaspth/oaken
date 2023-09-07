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
  class Stored::Abstract
    def initialize(type)
      @type = type
      @attributes = {}
    end

    def with(**attributes)
      if block_given?
        previous_attributes, @attributes = @attributes, @attributes.merge(attributes)
        yield
      else
        @attributes = attributes
      end
    ensure
      @attributes = previous_attributes if block_given?
    end

    def create(**attributes)
      @attributes.merge(**attributes)
    end
    alias :insert :create
  end

  class Stored::Memory < Stored::Abstract
    def find(id)
      objects.fetch(id)
    end

    # TODO: Figure out what to do for memory objects
    def access(id, **attributes)
      objects[id] = @type.new(**super(attributes))
    end

    private def objects
      @objects ||= {}
    end
  end

  class Stored::ActiveRecord < Stored::Abstract
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
      attributes = super
      @type.create!(**attributes)
    end

    def insert(**attributes)
      attributes = super
      @type.new(attributes).validate!
      @type.insert(attributes)
    end
  end

  module Seeds
    extend self

    class Provider < Struct.new(:data, :provider)
      def preregister(names)
        names.each do |name|
          type = Oaken.inflector.classify(name).safe_constantize and register type, name
        end
      end

      def register(type, key = Oaken.inflector.tableize(type.name))
        stored = provider.new(type)
        data.define_method(key) { stored }
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
        class_eval File.read(file)
      end
    end
  end
end
