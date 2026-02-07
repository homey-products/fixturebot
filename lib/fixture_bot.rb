# frozen_string_literal: true

require_relative "fixture_bot/version"
require_relative "fixture_bot/schema"
require_relative "fixture_bot/stable_id"
require_relative "fixture_bot/definition"
require_relative "fixture_bot/generator_context"
require_relative "fixture_bot/generator_proxy"
require_relative "fixture_bot/row_dsl"
require_relative "fixture_bot/fixture_set"

module FixtureBot
  class Error < StandardError; end

  def self.define(schema, &block)
    definition = Definition.new(schema)
    definition.instance_eval(&block)
    FixtureSet.new(schema, definition)
  end
end
