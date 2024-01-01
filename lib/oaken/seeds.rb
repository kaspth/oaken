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

  class << self
    # Expose a class `seed` method for individual test classes to use.
    # TODO: support parallelization somehow.
    def included(klass) = klass.singleton_class.delegate(:seed, to: Oaken::Seeds)

    def seed(*directories)
      Oaken.lookup_paths.product(directories).each do |path, directory|
        load_from Pathname(path).join(directory.to_s)
      end
    end

    private def load_from(path)
      @loader = Oaken::Loader.new path
      @loader.load_onto self
    ensure
      @loader = nil
    end
    def entry = @loader.entry
  end
end
