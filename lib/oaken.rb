# frozen_string_literal: true

require "oaken/version"
require "pathname"

module Oaken
  class Error < StandardError; end

  autoload :Seeds, "oaken/seeds"
  autoload :Entry, "oaken/entry"

  module Stored
    autoload :ActiveRecord, "oaken/stored/active_record"
  end

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

  singleton_class.attr_reader :lookup_paths
  @lookup_paths = ["db/seeds"]

  singleton_class.attr_accessor :store_path
  @store_path = Pathname.new "tmp/oaken/store"

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

      @entry = nil
    end
  end

  def self.seeds(&block)
    store_path.rmtree if ENV["OAKEN_RESET"]

    if block_given?
      Seeds.instance_eval(&block)
    else
      Rails.application.load_seed
    end

    Seeds
  end
end

require_relative "oaken/railtie" if defined?(Rails::Railtie)
