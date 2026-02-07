# frozen_string_literal: true

require "fixturebot/rails"

RSpec.configure do |config|
  config.before(:suite) do
    FixtureBot::Rails.generate
  end
end
