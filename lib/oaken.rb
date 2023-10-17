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
    delegate :loader, to: "Seeds"

    def initialize(key, type)
      @key, @type = key, type
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
        location = caller_locations(2, 10).find { _1.path.match?(/(db|test)\/seeds/) }
        # Seeds.result.run(location.path).add_reader @key, name, id, location
        instance_eval "def #{name}; find #{id}; end", location.path, location.lineno
      end
  end

  class Loader
    def initialize(seeds, directories)
      @seeds = seeds
      @entry_points = directories.to_h { [ _1, Entry.within(_1) ] }
    end

    def load_each
      @entry_points.each_value do |entries|
        entries.each do |entry|
          entry.load_onto @seeds
        end
      end
    end

    class Entry
      def self.within(directory)
        Pathname.glob("#{directory}{,/**/*}.rb").sort.map { new _1 }
      end

      def initialize(pathname)
        @pathname = pathname
      end

      def load_onto(seeds)
        seeds.class_eval @pathname.read, @pathname.to_s
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

  class Result
    def initialize(directory)
      @directory = directory
      @path = Pathname.new("./tmp/oaken-result-#{Rails.env}.yml")
      @runs = @path.exist? ? YAML.load(@path.read) : {}
      @runs.transform_values! { Run.new(**_1) }
      @runs.default_proc = ->(h, k) { h[k] = Run.new(path: k) }
    end

    def process
      Pathname.glob("#{@directory}{,/**/*}.rb").sort.each do |path|
        path = Oaken::Path.new(Oaken::Seeds, path)
        yield run(path), path
        self << path
      end

      write
    end

    def run(path)
      @runs[path.to_s]
    end

    def <<(path)
      run(path).checksum = path.checksum
    end

    def write
      @path.dirname.mkpath
      @path.write YAML.dump(@runs.transform_values(&:to_h))
    end

    class Run
      attr_accessor :checksum

      def initialize(path:, checksum: nil, readers: [])
        @path = path
        @checksum = checksum
        @readers = readers
      end

      def processed?(path)
        checksum == path.checksum
      end

      def replay(context)
        @readers.each do |config|
          key, name, id, path, lineno = config.values_at(:key, :name, :id, :path, :lineno)
          context.send(key).instance_eval "def #{name}; find #{id}; end", path, lineno
        end
      end

      def add_reader(key, name, id, location)
        @readers << { key: key, name: name, id: id, path: location.path, lineno: location.lineno }
      end

      def to_h
        { path: @path, checksum: @checksum, readers: @readers.uniq }
      end
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
