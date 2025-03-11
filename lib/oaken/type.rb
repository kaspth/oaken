# frozen_string_literal: true

class Oaken::Type < Data.define(:stitches)
  def self.for(name) = new(name.classify.gsub(/(?<=[a-z])(?=[A-Z])/))

  def locate
    possible_consts.filter_map(&:safe_constantize).first
  end
  def possible_consts = separator_matrix.map { stitch_with _1 }

  private
    def separator_matrix
      Enumerator.product(*grouped_separators * stitches.count).lazy
    end
    def stitch_with(separators) = stitches.each { separators.shift }

    define_method :grouped_separators, &[["::", ""]].method(:itself)
end
