# frozen_string_literal: true

require_relative "fixturebot/version"
require_relative "fixturebot/schema"
require_relative "fixturebot/stable_id"
require_relative "fixturebot/row"
require_relative "fixturebot/generator_context"
require_relative "fixturebot/generator_proxy"
require_relative "fixturebot/row_dsl"
require_relative "fixturebot/definition"
require_relative "fixturebot/record_builder"
require_relative "fixturebot/fixture_set"
require_relative "fixturebot/yaml_dumper"

module FixtureBot
  class Error < StandardError; end

  def self.define(schema, &block)
    definition = Definition.new(schema)
    definition.instance_eval(&block)
    FixtureSet.new(schema, definition)
  end

  def self.define_from_file(schema, fixtures_path)
    content = File.read(fixtures_path)
    definition = Definition.new(schema)
    definition.instance_eval(content, fixtures_path, 1)
    FixtureSet.new(schema, definition)
  end
end
