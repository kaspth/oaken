module Oaken::Seeds
  extend self

  def self.preregister(names)
    names.each do |name|
      type = Oaken.inflector.classify(name).safe_constantize and register type, name
    end
  end

  def self.register(type, key = Oaken.inflector.tableize(type.name))
    stored = Oaken::Stored::ActiveRecord.new(key, type)
    define_method(key) { stored }
  end

  singleton_class.attr_reader :loader
  delegate :entry, to: :loader

  def self.load_from(*paths)
    paths.each do |path|
      load_one path
    end
  end

  def self.load_one(path)
    @loader = Oaken::Loader.new(path)
    @loader.load_onto(self)
  end
end
