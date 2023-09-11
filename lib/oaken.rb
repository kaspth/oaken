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
        location = caller_locations.find { _1.path.start_with?("test/seeds") }
        instance_eval "def #{name}; find #{id}; end", location.path, location.lineno
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
      result = Result.new

      Pathname.glob("#{directory}{,/**/*}.rb").sort.each do |path|
        path = Path.new(self, path)
        path.process # unless result.run(path.to_s)[:checksum] == path.checksum

        result << path
      end

      result.write
    end
  end

  class Result
    def initialize
      @path = Pathname.new("./tmp/oaken-result.yml")
      @runs = @path.exist? ? YAML.load(@path.read) : {}
    end

    def run(path)
      @runs[path.to_s]
    end

    def <<(path)
      @runs[path.to_s] = { checksum: path.checksum }
    end

    def write
      @path.write YAML.dump(@runs)
    end
  end

  class Path
    def initialize(context, path)
      @context, @path = context, path
      @source = path.read
    end

    def to_s
      @path.to_s
    end

    def checksum
      Digest::MD5.hexdigest @source
    end

    def process
      @context.class_eval @source, to_s
    end
  end
end
