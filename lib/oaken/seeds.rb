module Oaken::Seeds
  extend self

  def self.respond_to_missing?(name, ...)
    Oaken.inflector.classify(name).safe_constantize || super
  end

  def self.method_missing(meth, ...)
    name = meth.to_s
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

  module Loading
    def seed(*directories)
      Oaken.lookup_paths.each do |path|
        directories.each do |directory|
          @loader = Oaken::Loader.new Pathname(path).join(directory.to_s)
          @loader.load_onto Oaken::Seeds
        end
      end
    end
  end
  extend Loading

  def self.included(klass)
    klass.extend Loading
  end
end
