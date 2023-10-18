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
    stored = provider.new(type, key) and define_method(key) { stored }
  end
  def self.provider = Oaken::Stored::ActiveRecord
end
