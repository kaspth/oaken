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

  class Type
    def self.for(name) = new(name.classify)
    def initialize(name)
      @name = name
      @offsets = descending_offsets
    end

    def locate
      p @offsets
      matrix.map do |gates|
        p gates
        @name.dup.tap do |name|
          @offsets.each_with_index do |offset, index|
            name.slice! offset, 2 if gates[index]
          end
        end
      end
    end

    private
      def matrix
        @offsets.map { [false, true] }.then { |f, *r| f.product(*r) }
      end

      def descending_offsets
        name.scan("::").reduce [] do |offsets, _|
          offsets << name.rindex("::", offsets.last.to_i.succ)
        end
      end
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

    def self.definition_location
      # Trickery abounds! Due to Ruby's `caller_locations` + our `load_onto`'s `class_eval` above
      # we can use this format to detect the location in the seed file where the call came from.
      caller_locations(2, 8).find { _1.label.match? /block .*?load_onto/ }
    end
  end

  def self.prepare(&block) = Seeds.instance_eval(&block)
  def self.load_seed = Rails.application.load_seed
end

require_relative "oaken/railtie" if defined?(Rails::Railtie)
