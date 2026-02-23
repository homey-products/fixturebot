# frozen_string_literal: true

require_relative "lib/fixturebot/version"

Gem::Specification.new do |spec|
  spec.name = "fixturebot-rails"
  spec.version = FixtureBot::VERSION
  spec.authors = ["Brad Gessler"]
  spec.email = ["bradgessler@gmail.com"]

  spec.summary = "Define Rails fixtures with a Ruby DSL instead of writing YAML by hand"
  spec.description = "FixtureBot gives you a Ruby DSL that feels like FactoryBot, backed by the speed of Rails fixtures. Define your test data in Ruby and generate standard YAML fixture files."
  spec.homepage = "https://github.com/rubymonolith/fixturebot"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/rubymonolith/fixturebot"
  spec.metadata["changelog_uri"] = "https://github.com/rubymonolith/fixturebot/blob/main/CHANGELOG.md"

  spec.files = Dir["lib/**/*", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "activerecord", ">= 7.0"
end
