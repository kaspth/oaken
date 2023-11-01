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
    @model_paths = []
    @root_model = ActiveModel::Name.new(options[:root_model].constantize)

    empty_directory_with_keep_file "db/seeds/#{@root_model.collection}"
    empty_directory_with_keep_file "db/seeds/data"
    empty_directory_with_keep_file "db/seeds/test/cases"
  end

  def convert_all
    fixtures = Pathname.glob("test/fixtures/**/*.yml").to_h { [_1.to_s, YAML.load_file(_1)] }
    roots = fixtures.delete("test/fixtures/#{@root_model.collection}.yml")

    roots.each do |name, data|
      results = fixtures.flat_map do |path, hash|
        hash.map do |inner_name, attributes|
          if name == attributes[@root_model.collection] || attributes[@root_model.singular]
            model_path = path.sub("test/fixtures/", "").chomp(".yml")
            convert_one(model_path, inner_name => attributes)
          end
        end
      end

      model_path = @root_model.collection
      create_file "db/seeds/test/#{model_path}/#{name}.rb", ["#{name} = #{convert_one(model_path, name => data)}", *results].compact.join("\n")
    end

    # fixtures.each do |file|
    #   yaml = YAML.load_file(file)

    #   @model_paths << model_path = file.relative_path_from("test/fixtures").sub_ext("").to_s
    #   output_file = file.sub("test/fixtures", "db/seeds/test/#{@root_model.collection}").sub_ext(".rb")
    #   create_file output_file, convert_one(model_path, yaml) || ""
    # rescue Psych::SyntaxError
    #   say "Skipped #{fixture_file} due to ERB content or other YAML parsing issues.", :yellow
    # end
  end

  def prepend_setup_to_seeds
    registers = @model_paths.uniq.sort.join(", ").presence
    registers = "\nregister #{registers}\n\n" if registers

    inject_into_file "db/seeds.rb", <<~RUBY, before: /\A/
      Oaken.prepare do
        self.root_model = #{@root_model.name}\n#{registers}
        load :#{@root_model.collection}, :data
      end
    RUBY
  end

  private
    def convert_one(model_path, contents)
      if contents
        model_name = model_path.tr("/", "_")

        contents.map do |key, attributes|
          "#{model_name}.create :#{key}, #{convert_hash(attributes)}"
        end.join("\n").tap do
          _1.prepend "register #{model_path.classify}\n" if model_path.include?("/")
        end
      end
    end

    def recursive_convert(input, key: nil)
      case input
      when Hash  then "{ #{convert_hash(input)} }"
      when Array then input.map { recursive_convert _1 }.join(", ")
      else
        [@root_model.collection, @root_model.singular].include?(key) ? input : "\"#{input}\""
      end
    end

    def convert_hash(hash)
      hash.map { |k, v| "#{k}: #{recursive_convert(v, key: k)}" }.join(", ")
    end

    def empty_directory_with_keep_file(name)
      empty_directory name
      create_file "#{name}/.keep" if options[:keeps]
    end
end
