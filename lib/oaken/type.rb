# frozen_string_literal: true

class Oaken::Type < Struct.new(:name, :gsub)
  def self.for(name) = new(name, name.classify.gsub(/(?<=[a-z])(?=[A-Z])/))

  def locate
    possible_consts.filter_map(&:safe_constantize).first
  end

  def possible_consts
    separator_matrixes.fetch(gsub.count).map { |seps| gsub.with_index { seps[_2] } }
  rescue KeyError
    raise ArgumentError, "can't resolve #{name} to an object, please call register manually"
  end

  private
    # TODO: Remove after dropping Ruby 3.1 support
    if Enumerator.respond_to?(:product)
      def self.product(...) = Enumerator.product(...)
    else
      def self.product(first = nil, *rest) = first&.product(*rest) || [[]]
    end

    separator_matrixes = (0..3).to_h { |size| [size, product(*[["::", ""]].*(size)).lazy] }
    define_method(:separator_matrixes) { separator_matrixes }
end
