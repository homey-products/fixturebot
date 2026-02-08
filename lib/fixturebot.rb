# frozen_string_literal: true

require_relative "fixturebot/version"
require_relative "fixturebot/schema"
require_relative "fixturebot/key"
require_relative "fixturebot/default"
require_relative "fixturebot/default_context"
require_relative "fixturebot/row"
require_relative "fixturebot/row_definition"
require_relative "fixturebot/row_builder"
require_relative "fixturebot/definition"
require_relative "fixturebot/fixture_set"
require_relative "fixturebot/yaml_dumper"
require_relative "fixturebot/cli"

module FixtureBot
  class Error < StandardError; end

  # Programmatic API: FixtureBot.define(schema) { ... }
  # File API (no schema): FixtureBot.define { ... } — registers block for define_from_file
  def self.define(schema = nil, &block)
    if schema
      definition = Definition.new(schema)
      evaluate_block(definition, block)
      FixtureSet.new(schema, definition)
    else
      @pending_blocks ||= []
      @pending_blocks << block
      nil
    end
  end

  def self.define_from_file(schema, fixtures_path)
    @pending_blocks = []
    content = File.read(fixtures_path)
    eval(content, TOPLEVEL_BINDING, fixtures_path, 1)

    definition = Definition.new(schema)
    @pending_blocks.each { |blk| evaluate_block(definition, blk) }
    @pending_blocks = nil
    FixtureSet.new(schema, definition)
  end

  def self.evaluate_block(definition, block)
    if block.arity > 0
      block.call(definition)
    else
      definition.instance_eval(&block)
    end
  end
  private_class_method :evaluate_block
end
