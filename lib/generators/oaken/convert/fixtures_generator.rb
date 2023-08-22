require "rails/generators/base"
require "yaml"

module Oaken::Convert; end
class Oaken::Convert::FixturesGenerator < Rails::Generators::Base
  desc "Converts Rails fixtures to Oaken seeds"
  source_root File.expand_path("templates", __dir__)

  def convert
    path = Pathname.new("test/fixtures")

    Pathname.glob("**/*.{yml,yaml}", base: path) do |fixture_file|
      output_file = Pathname.new("test/seeds") / fixture_file.sub_ext(".rb")

      if parsed = parse_fixture_file(path / fixture_file)
        output = parsed.map do |key, attributes|
          model_name = output_file.basename(".*")
          attribute_strings = attributes.map { |k, v| "#{k}: #{recursive_convert(v)}" }.join(", ")
          "#{model_name}.update :#{key}, #{attribute_strings}"
        end

        create_file output_file, output.join("\n")
      else
        create_file output_file, ""
      end
    rescue Psych::SyntaxError
      say "Skipped #{fixture_file} due to ERB content or other YAML parsing issues.", :yellow
    end
  end

  private
    def parse_fixture_file(path)
      YAML.load_file(path)
    end

    def recursive_convert(input)
      if input.is_a?(Hash)
        inner_hash = input.map { |k, v| "#{k}: #{recursive_convert(v)}" }.join(", ")
        "{ #{inner_hash} }"
      elsif input.is_a?(Array)
        input.map { |item| recursive_convert(item) }.join(", ")
      else
        "\"#{input}\""
      end
    end
end
