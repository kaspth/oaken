# frozen_string_literal: true

require "rails/generators/base"
require "yaml"

module Oaken::Convert; end
class Oaken::Convert::FixturesGenerator < Rails::Generators::Base
  desc "Converts fixtures to Oaken seeds in db/seeds/test"
  source_root File.expand_path("templates", __dir__)

  class_option :root_model, required: true
  class_option :keeps, type: :boolean, default: true

  def prepare
    @root_model = ActiveModel::Name.new(options[:root_model].constantize)
    empty_directory_with_keep_file "db/seeds/data"
    empty_directory_with_keep_file "db/seeds/test/cases"
  end

  def parse
    @fixtures = Pathname.glob("test/fixtures/**/*.yml").to_h do
      [_1.to_s.delete_prefix("test/fixtures/").chomp(".yml"), YAML.load_file(_1)]
    rescue Psych::SyntaxError
      say "Skipped #{_1} due to ERB content or other YAML parsing issues.", :yellow
    end.tap(&:compact_blank!)
  end

  def convert_all
    Fixture.traverse(@fixtures, @root_model.collection).each do |fixture|
      create_file "db/seeds/test/#{@root_model.plural}/#{fixture.name}.rb", fixture.render
    end
  end

  def prepend_setup_to_seeds
    namespaced_models = @fixtures.keys.filter_map { _1.classify if _1.include?("/") }.uniq.sort
    registers = "register #{namespaced_models.join(", ")}\n" if namespaced_models.any?

    inject_into_file "db/seeds.rb", <<~RUBY, before: /\A/
      Oaken.prepare do
        #{registers}
        load :#{@root_model.plural}, :data
      end
    RUBY
  end

  private
    class Fixture
      attr_reader :model_name, :name

      def initialize(model_name, name, attributes, descendants = [])
        @model_name, @name, @attributes, @descendants = model_name.tr("/", "_"), name, attributes, descendants
        @plural = @model_name
        @singular = @model_name.singularize
      end

      def self.traverse(fixtures, root_model_name)
        fixtures = fixtures.to_h do |model_name, rows|
          [model_name, rows.map { Fixture.new(model_name, _1, _2) }]
        end

        fixtures.delete(root_model_name).each do |fixture|
          fixtures.each_value do |rows|
            fixture.extract_descendants rows
          end
        end
      end

      def extract_descendants(rows)
        referenced = rows.select { _1.reference(plural, singular) == name }
        descendants.concat referenced
        rows.replace rows - referenced
      end

      def reference(plural, singular)
        @referenced = plural   if attributes[plural]
        @referenced = singular if attributes[singular]
        attributes[@referenced]
      end

      def render
        [render_self, *descendants.map(&:render)].join("\n")
      end

      private
        attr_reader :attributes, :descendants
        attr_reader :plural, :singular

        def render_self
          "#{model_name}.create :#{name}, #{convert_hash(attributes)}".tap do
            _1.prepend "#{name} = " if descendants.any?
          end
        end

        def convert_hash(hash)
          hash.map { |k, v| "#{k}: #{recursive_convert(v, key: k)}" }.join(", ")
        end

        def recursive_convert(input, key: nil)
          case input
          when Hash  then "{ #{convert_hash(input)} }"
          when Array then input.map { recursive_convert _1 }.join(", ")
          when Integer then input
          else
            key == @referenced ? input : "\"#{input}\""
          end
        end
    end

    def empty_directory_with_keep_file(name)
      empty_directory name
      create_file "#{name}/.keep" if options[:keeps]
    end
end
