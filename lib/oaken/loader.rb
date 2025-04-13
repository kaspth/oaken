class Oaken::Loader
  def self.from(identifiers)
    new identifiers.flat_map { Oaken.glob _1 }
  end

  def initialize(entries)
    @entries = entries
  end

  def load_onto(seeds) = @entries.each do |path|
    ActiveRecord::Base.transaction do
      seeds.class_eval path.read, path.to_s
    end
  end

  def self.definition_location
    # Trickery abounds! Due to Ruby's `caller_locations` + our `load_onto`'s `class_eval` above
    # we can use this format to detect the location in the seed file where the call came from.
    caller_locations(2, 8).find { _1.label.match? /block .*?load_onto/ }
  end
end
