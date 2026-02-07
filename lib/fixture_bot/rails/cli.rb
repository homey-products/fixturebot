# frozen_string_literal: true

require "thor"

module FixtureBot
  module Rails
    class CLI < Thor
      def self.exit_on_failure?
        true
      end

      desc "generate FIXTURES_FILE [OUTPUT_DIR]", "Generate YAML fixtures from a DSL file"
      option :schema, type: :string, default: "db/schema.rb", aliases: "-s", desc: "Path to schema.rb"
      def generate(fixtures_path, output_dir = "test/fixtures")
        schema_path = options[:schema]

        unless File.exist?(schema_path)
          raise Thor::Error, "Schema file not found: #{schema_path}"
        end

        unless File.exist?(fixtures_path)
          raise Thor::Error, "Fixtures file not found: #{fixtures_path}"
        end

        schema = SchemaLoader.load_file(schema_path)
        fixture_set = FixtureBot.define_from_file(schema, fixtures_path)
        YamlDumper.new(fixture_set).dump(output_dir)

        say "Generated fixtures in #{output_dir}/"
        fixture_set.tables.each do |table_name, records|
          next if records.empty?
          say "  #{table_name}.yml (#{records.size} records)"
        end
      end

      map %w[-v --version] => :version
      desc "version", "Show version"
      def version
        say "fixturebot #{FixtureBot::VERSION}"
      end
    end
  end
end
