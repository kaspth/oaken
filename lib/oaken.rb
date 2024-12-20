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

  class Loader
    def initialize(path)
      @entries = Pathname.glob("#{path}{,/**/*}.rb").sort
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
