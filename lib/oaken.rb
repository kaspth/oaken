# frozen_string_literal: true

require "oaken/version"
require "pathname"

module Oaken
  class Error < StandardError; end

  autoload :Seeds,     "oaken/seeds"
  autoload :TestSetup, "oaken/test_setup"

  module Stored
    autoload :ActiveRecord, "oaken/stored/active_record"
  end

  singleton_class.attr_reader :lookup_paths
  @lookup_paths = ["db/seeds"]

  def self.lookups_from(paths)
    lookup_paths.product(paths).map(&File.method(:join))
  end

  class NoSeedsFoundError < ArgumentError; end

  class Loader
    def self.from(paths)
      new Path.expand(paths).sort
    end

    def initialize(paths)
      @paths = paths
    end

    def load_onto(seeds) = @paths.each do |path|
      ActiveRecord::Base.transaction do
        seeds.class_eval path.read, path.to_s
      end
    end

    class Path
      def self.expand(paths)
        patterns = Oaken.lookups_from(paths).map { new _1 }
        patterns.flat_map(&:to_a).tap do |found|
          raise Oaken::NoSeedsFoundError, "found no seed files for #{paths.map(&:inspect).join(", ")} when searching with #{patterns.join(", ")}" if found.none?
        end
      end

      def initialize(path)
        @pattern = "#{path}{,/**/*}.rb"
      end
      def to_s = @pattern
      def to_a = Pathname.glob(@pattern)
    end
  end

  def self.prepare(&block) = Seeds.instance_eval(&block)
  def self.load_seed = Rails.application.load_seed
end

require_relative "oaken/railtie" if defined?(Rails::Railtie)
