require 'rails/generators/base'
require 'yaml'

module Oaken
  module Generators
    class FixtureConverterGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc "This generator converts Rails fixtures to seedable models"

      def convert_fixtures_to_seeds
        fixtures_path = Rails.root.join('test/fixtures')
        seeds_path = Rails.root.join('test/seeds')

        Dir.glob("#{fixtures_path}/**/*.{yml,yaml}") do |fixture_file|
          begin
            relative_path = Pathname.new(fixture_file).relative_path_from(fixtures_path)
            output_file = seeds_path.join(relative_path.sub_ext(".rb"))

            FileUtils.mkdir_p(output_file.dirname)

            parsed_data = parse_fixture_file fixture_file

            unless parsed_data
              say "Skipped '#{fixture_file}' due to the fixture file being empty", :yellow
              next
            end

            output = []
            parsed_data.each do |key, attributes|
              model_name = File.basename(relative_path, ".*")
              attribute_strings = attributes.map { |k, v| "#{k}: #{recursive_convert(v)}" }.join(', ')
              output << "#{model_name}.update :#{key}, #{attribute_strings}"
            end

            output_file.write output.join("\n")

            say "Converted #{fixture_file} to #{output_file}", :green
          rescue Psych::SyntaxError
            say "Skipped '#{fixture_file}' due to ERB content or other YAML parsing issues.", :yellow
          end
        end
      end

      private
        def parse_fixture_file(path)
          YAML.load_file(path)
        end

        def recursive_convert(input)
          if input.is_a?(Hash)
            inner_hash = input.map { |k, v| "#{k}: #{recursive_convert(v)}" }.join(', ')
            "{ #{inner_hash} }"
          elsif input.is_a?(Array)
            input.map { |item| recursive_convert(item) }.join(', ')
          else
            "\"#{input}\""
          end
        end
    end
  end
end
