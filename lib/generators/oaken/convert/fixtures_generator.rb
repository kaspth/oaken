# frozen_string_literal: true

require "rails/generators/base"
require "yaml"

module Oaken::Convert; end
class Oaken::Convert::Fixture
  attr_reader :model_name, :name

  def initialize(model_name, name, attributes)
    @model_name, @name, @attributes = model_name.tr("/", "_"), name, attributes
    @plural = @model_name
    @singular = @model_name.singularize
  end

  def extract_dependents(fixtures)
    @dependents = fixtures.select { _1.reference(plural, singular) == name }
    fixtures.replace fixtures - dependents

    dependents.each { _1.extract_dependents fixtures }
  end

  def reference(plural, singular)
    @referenced = [plural, :plural]     if attributes[plural]
    @referenced = [singular, :singular] if attributes[singular]
    attributes[@referenced&.first]
  end

  def render(delimiter: "\n")
    [render_self, dependents&.map { _1.render delimiter: nil }].join(delimiter)
  end

  private
    attr_reader :attributes, :dependents
    attr_reader :plural, :singular

    def render_self
      "#{model_name}.create :#{name}, #{convert_hash(attributes)}\n".tap do
        _1.prepend "#{name} = " if dependents&.any?
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
        if key == @referenced&.first
          @referenced.last == :plural ? "[#{input}]" : input
        else
          "\"#{input}\""
        end
      end
    end
end

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
    @fixtures = Dir.glob("test/fixtures/**/*.yml").to_h do |path|
      model_name = path.delete_prefix("test/fixtures/").chomp(".yml")
      [model_name, YAML.unsafe_load_file(path).presence&.map { Oaken::Convert::Fixture.new(model_name, _1, _2) }]
    rescue Psych::SyntaxError
      say "Skipped #{path} due to ERB content or other YAML parsing issues.", :yellow
    end.tap(&:compact_blank!)
  end

  def prepend_prepare_to_seeds
    namespaces = @fixtures.keys.filter_map { _1.classify if _1.include?("/") }.uniq.sort

    code  = +"Oaken.prepare do\n"
    code << "  register #{namespaces.join(", ")}\n\n" if namespaces.any?
    code << "  seed :#{@root_model.plural}, :data\n"
    code << "end\n"

    inject_into_file "db/seeds.rb", code, before: /\A/
  end

  def convert_all
    roots = @fixtures.delete(@root_model.collection)
    @fixtures = @fixtures.values.flatten

    roots.each do |fixture|
      fixture.extract_dependents @fixtures
      create_file "db/seeds/test/#{@root_model.plural}/#{fixture.name}.rb", fixture.render.chomp
    end

    @fixtures.group_by(&:model_name).each do |model_name, fixtures|
      create_file "db/seeds/test/data/#{model_name}.rb", fixtures.map(&:render).join.chomp
    end
  end

  private
    def empty_directory_with_keep_file(name)
      empty_directory name
      create_file "#{name}/.keep" if options[:keeps]
    end
end
