# frozen_string_literal: true

require "rails/generators/base"
require "yaml"

module Oaken::Convert; end
class Oaken::Convert::FixturesGenerator < Rails::Generators::Base
  desc "Converts Rails fixtures to Oaken seeds"
  source_root File.expand_path("templates", __dir__)

  def convert_all
    Pathname.glob("test/fixtures/**/*.{yml,yaml}") do |file|
      yaml = YAML.load_file(file)

      model_path  = file.relative_path_from("test/fixtures").sub_ext("").to_s
      output_file = file.sub("fixtures", "seeds").sub_ext(".rb")
      create_file output_file, convert_one(model_path, yaml) || ""
    rescue Psych::SyntaxError
      say "Skipped #{fixture_file} due to ERB content or other YAML parsing issues.", :yellow
    end
  end

  private
    def convert_one(model_path, contents)
      if contents
        model_name = model_path.tr("/", "_")

        contents.map do |key, attributes|
          "#{model_name}.update :#{key}, #{convert_hash(attributes)}"
        end.join("\n").tap do
          _1.prepend "register #{model_path.classify}\n" if model_path.include?("/")
        end
      end
    end

    def recursive_convert(input, wrap: true)
      case input
      when Hash  then "{ #{convert_hash(input)} }"
      when Array then input.map { recursive_convert _1 }.join(", ")
      else
        "\"#{input}\""
      end
    end

    def convert_hash(hash)
      hash.map { |k, v| "#{k}: #{recursive_convert(v)}" }.join(", ")
    end
end
