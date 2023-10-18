module Oaken::Seeds
  extend self

  def self.respond_to_missing?(name, ...)
    Oaken.inflector.classify(name).safe_constantize || super
  end

  def self.method_missing(name, ...)
    name = name.to_s
    if type = Oaken.inflector.classify(name).safe_constantize
      register type, name
      public_send(name, ...)
    else
      super
    end
  end

  def self.register(type, key = nil)
    stored = provider.new(type, key) and define_method(stored.key) { stored }
  end
  def self.provider = Oaken::Stored::ActiveRecord

  singleton_class.attr_reader :loader
  delegate :entry, to: :loader

  def self.load(directory = "db/seeds", include_env:)
    @loader = Oaken::Loader.new directory, exclude: environments - [include_env]
    @loader.load_onto self
  end

  def self.environments
    Pathname("config/environments").children.map { _1.basename(_1.extname).to_s }
  end
end
