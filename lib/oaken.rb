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

    def update(id, **attributes)
      self.class.define_method(id) { find(id) }

      klass = nil
      attributes = @attributes.merge(attributes)
      attributes.transform_values! do |value|
        if !value.respond_to?(:call) then value else
          klass ||= Struct.new(:id, *attributes.keys).new(id, *attributes.values)
          klass.instance_exec(&value)
        end
      end
    end

    alias :upsert :update
  end

  class Stored::Memory < Stored::Abstract
    def find(id)
      objects.fetch(id)
    end

    def update(id, **attributes)
      attributes = super
      objects[id] = @type.new(**attributes)
    end

    private def objects
      @objects ||= {}
    end
  end

  class Stored::ActiveRecord < Stored::Abstract
    def find(id)
      @type.find identify id
    end

    def update(id, **attributes)
      attributes = super

      if record = @type.find_by(id: identify(id))
        record.update!(**attributes)
      else
        @type.create!(id: identify(id), **attributes)
      end
    end

    def upsert(id, **attributes)
      attributes = super
      @type.new(attributes).validate!
      @type.upsert({ id: identify(id), **attributes })
    end

    private def identify(id) = ::ActiveRecord::FixtureSet.identify(id, @type.type_for_attribute(@type.primary_key).type)
  end

  module Data
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
        Oaken::Data.class_eval File.read(file)
      end
    end
  end
end
