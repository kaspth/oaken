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

  class Type < Data.define(:splice)
    def self.for(name) = new(name.classify.gsub(/(?<=[a-z])(?=[A-Z])/))

    def locate
      possible_consts.filter_map(&:safe_constantize).first
    end

    private
      GROUPED_SEPARATORS = [["::", ""]]

      def possible_consts
        separator_matrix.lazy.map { |parts| splice.with_index { parts[_2] } }
      end
      def separator_matrix = (GROUPED_SEPARATORS * splice.count.clamp(1..)).then { |it, *rest| it.product(*rest) }
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
