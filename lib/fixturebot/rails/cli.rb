# frozen_string_literal: true

require "fixturebot/cli"

module FixtureBot
  module Rails
    class CLI < FixtureBot::CLI
      desc "compile FIXTURES_FILE [OUTPUT_DIR]", "Compile FixtureBot DSL to YAML fixture files"
      def compile(fixtures_path, output_dir = "test/fixtures")
        unless File.exist?(fixtures_path)
          raise Thor::Error, "Fixtures file not found: #{fixtures_path}"
        end

        schema = SchemaLoader.load
        fixture_set = FixtureBot.define_from_file(schema, fixtures_path)
        Compiler.new(fixture_set, schema: schema).compile(output_dir)

        say "Compiled fixtures to #{output_dir}/"
        fixture_set.tables.each do |table_name, records|
          next if records.empty?
          say "  #{table_name}.yml (#{records.size} records)"
        end
      end
    end
  end
end
