class Oaken::Entry
  def self.within(directory)
    Pathname.glob("#{directory}{,/**/*}.{rb,sql}").sort.map { new _1 }
  end

  def initialize(pathname)
    @file, @pathname = pathname.to_s, pathname
  end

  def load_onto(seeds)
    Oaken.transaction do
      case @pathname.extname
      in ".rb"  then seeds.class_eval @pathname.read, @file
      in ".sql" then ActiveRecord::Base.connection.execute @pathname.read
      end
    end
  end
end
