class Oaken::Stored::ActiveRecord < Struct.new(:key, :type)
  delegate :find, to: :type

  def create(reader = nil, **attributes)
    type.create!(**attributes).tap do |record|
      define_reader reader, record.id if reader
    end
  end

  def insert(reader = nil, **attributes)
    type.new(attributes).validate!
    type.insert(attributes).tap do
      define_reader reader, type.where(attributes).pick(:id) if reader
    end
  end

  def define_reader(name, id)
    Oaken::Seeds.entry.define_reader(self, name, id)
  end
end
