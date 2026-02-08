# frozen_string_literal: true

require "fixturebot/rails"

RSpec.configure do |config|
  config.before(:suite) do
    FixtureBot::Rails.compile
  end
end
