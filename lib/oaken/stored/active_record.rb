class Oaken::Stored::ActiveRecord < Struct.new(:type, :key)
  def initialize(type, key = nil)
    super(type, key || Oaken.inflector.tableize(type.name))
  end
  delegate :insert_all, to: :type

  def find(...)
    type.find(...)
  rescue ActiveRecord::RecordNotFound
    # When a database's data has changed without touching any Oaken seed, Oaken thinks
    # its cache is still valid, as no checksums have changed, however the underlying data is no longer there.
    # The `find` call raises in that case and we can remove the cache for that seed file.
    location = caller_locations(2, 1).first
    Oaken::Entry.new(Pathname(location.path)).remove
    raise "Database data changed without Oaken knowing: missing record originally created on #{location}. Oaken has reset the file's cache, try rerunning the command."
  end

  def create(reader = nil, **attributes)
    lineno = caller_locations(1, 1).first.lineno

    type.create!(**attributes).tap do |record|
      define_reader reader, record.id, lineno if reader
    end
  end

  def insert(reader = nil, **attributes)
    lineno = caller_locations(1, 1).first.lineno

    type.new(attributes).validate!
    type.insert(attributes).tap do
      define_reader reader, type.where(attributes).pick(:id), lineno if reader
    end
  end

  def define_reader(...)
    Oaken::Seeds.entry.define_reader(self, ...)
  end
end
