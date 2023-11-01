require "digest/md5"
require "pstore"

class Oaken::Entry < DelegateClass(PStore)
  def self.store_accessor(name)
    define_method(name) { self[name] } and define_method("#{name}=") { |value| self[name] = value }
  end
  store_accessor :checksum
  store_accessor :readers

  def self.within(directory)
    Pathname.glob("#{directory}{,/**/*}.{rb,sql}").sort.map { new _1 }
  end

  def initialize(pathname)
    @file, @pathname = pathname.to_s, pathname
    @computed_checksum = Digest::MD5.hexdigest(@pathname.read)

    prepared_store_path = Oaken.store_path.join(pathname).tap { _1.dirname.mkpath }
    super PStore.new(prepared_store_path)
  end

  def load_onto(seeds)
    transaction do
      if replay?
        puts "Replaying #{@file}…"
        readers.each do |key, *args|
          define_reader(seeds.send(key), *args)
        end
      else
        reset

        case @pathname.extname
        in ".rb"  then seeds.class_eval @pathname.read, @file
        in ".sql" then ActiveRecord::Base.connection.execute @pathname.read
        end
      end
    end
  end

  def transaction(&block)
    super do
      Oaken.transaction(&block)
    end
  end

  def replay?
    checksum == @computed_checksum
  end

  def reset
    self.checksum = @computed_checksum
    self.readers  = Set.new
  end

  def define_reader(stored, name, id, lineno)
    stored.instance_eval "def #{name}; find #{id}; end", @file, lineno
    readers << [stored.key, name, id, lineno]
  end
end
