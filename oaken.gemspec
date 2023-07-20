# frozen_string_literal: true

require_relative "lib/oaken/version"

Gem::Specification.new do |spec|
  spec.name = "oaken"
  spec.version = Oaken::VERSION
  spec.authors = ["Kasper Timm Hansen"]
  spec.email = ["hey@kaspth.com"]

  spec.summary = "Oaken aims to blend your Fixtures/Factories and levels up your database seeds."
  spec.homepage = "https://kaspthrb.gumroad.com/l/open-source-retreat-summer-2023"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kaspth/oaken"
  spec.metadata["changelog_uri"]   = "https://github.com/kaspth/oaken/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do
      (File.expand_path(_1) == __FILE__) || _1.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { File.basename(_1) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
