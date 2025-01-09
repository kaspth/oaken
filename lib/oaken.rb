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

  def self.glob(identifier)
    patterns = lookup_paths.map { File.join _1, "#{identifier}{,/**/*}.rb" }

    Pathname.glob(patterns).tap do |found|
      raise NoSeedsFoundError, "found no seed files for #{identifier.inspect}" if found.none?
    end
  end
  NoSeedsFoundError = Class.new ArgumentError

  class Loader
    def self.from(identifiers)
      new identifiers.flat_map { Oaken.glob _1 }
    end

    def initialize(entries)
      @entries = entries
    end

    def load_onto(seeds) = @entries.each do |path|
      ActiveRecord::Base.transaction do
        seeds.class_eval path.read, path.to_s
      end
    end
  end

  def self.prepare(&block) = Seeds.instance_eval(&block)
  def self.load_seed = Rails.application.load_seed
end

require_relative "oaken/railtie" if defined?(Rails::Railtie)
