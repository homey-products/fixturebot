# frozen_string_literal: true

require "fixturebot"
require_relative "rails/schema_loader"
require_relative "rails/railtie" if defined?(::Rails::Railtie)

module FixtureBot
  module Rails
    def self.compile(fixtures_file: nil, output_dir: nil)
      fixtures_file = resolve_fixtures_file(fixtures_file)
      return unless fixtures_file && File.exist?(fixtures_file)

      output_dir = resolve_output_dir(output_dir, fixtures_file)

      schema = SchemaLoader.load
      fixture_set = FixtureBot.define_from_file(schema, fixtures_file)
      Compiler.new(fixture_set).compile(output_dir)
    end

    def self.resolve_fixtures_file(explicit)
      return explicit if explicit

      if defined?(::Rails::Railtie) && ::Rails.application&.config&.respond_to?(:fixturebot)
        configured = ::Rails.application.config.fixturebot.fixtures_file
        return configured if configured
      end

      detect_fixtures_file
    end
    private_class_method :resolve_fixtures_file

    def self.resolve_output_dir(explicit, fixtures_file)
      return explicit if explicit

      if defined?(::Rails::Railtie) && ::Rails.application&.config&.respond_to?(:fixturebot)
        configured = ::Rails.application.config.fixturebot.output_dir
        return configured if configured
      end

      detect_output_dir(fixtures_file)
    end
    private_class_method :resolve_output_dir

    def self.detect_fixtures_file
      %w[test/fixtures.rb spec/fixtures.rb].find { |f| File.exist?(f) }
    end
    private_class_method :detect_fixtures_file

    def self.detect_output_dir(fixtures_file)
      fixtures_file.sub(/\.rb\z/, "")
    end
    private_class_method :detect_output_dir
  end
end
