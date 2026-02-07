# frozen_string_literal: true

require "fixturebot/cli"

module FixtureBot
  module Rails
    class CLI < FixtureBot::CLI
      desc "generate FIXTURES_FILE [OUTPUT_DIR]", "Generate YAML fixtures from a DSL file"
      def generate(fixtures_path, output_dir = "test/fixtures")
        unless File.exist?(fixtures_path)
          raise Thor::Error, "Fixtures file not found: #{fixtures_path}"
        end

        schema = SchemaLoader.load
        fixture_set = FixtureBot.define_from_file(schema, fixtures_path)
        YamlDumper.new(fixture_set).dump(output_dir)

        say "Generated fixtures in #{output_dir}/"
        fixture_set.tables.each do |table_name, records|
          next if records.empty?
          say "  #{table_name}.yml (#{records.size} records)"
        end
      end
    end
  end
end
