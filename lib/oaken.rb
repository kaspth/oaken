# frozen_string_literal: true

require "oaken/version"
require "pathname"

require "active_support/core_ext/module/delegation"

module Oaken
  class Error < StandardError; end

  autoload :Loader,    "oaken/loader"
  autoload :Seeds,     "oaken/seeds"
  autoload :TestSetup, "oaken/test_setup"

  module Stored
    autoload :ActiveRecord, "oaken/stored/active_record"
  end

  singleton_class.attr_accessor :loader
  singleton_class.delegate *Loader.public_instance_methods(false), to: :loader
  @loader = Loader.new lookup_paths: "db/seeds"
end

require_relative "oaken/railtie" if defined?(Rails::Railtie)
