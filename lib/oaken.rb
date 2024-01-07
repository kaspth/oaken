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

  class Loader
    def initialize(path)
      @entries = Pathname.glob("#{path}{,/**/*}.{rb,sql}").sort
    end

    def load_onto(seeds)
      @entries.each do |path|
        Oaken.transaction do
          case path.extname
          when ".rb"  then seeds.class_eval path.read, path.to_s
          when ".sql" then ActiveRecord::Base.connection.execute path.read
          end
        end
      end
    end
  end

  def self.transaction(&block)
    ActiveRecord::Base.transaction(&block)
  end

  def self.prepare(&block)
    Seeds.instance_eval(&block)
    Seeds
  end

  def self.load_seed = Rails.application.load_seed
end

require_relative "oaken/railtie" if defined?(Rails::Railtie)
