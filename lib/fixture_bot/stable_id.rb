# frozen_string_literal: true

require "zlib"

module FixtureBot
  module StableId
    def self.generate(table_name, record_name)
      Zlib.crc32("#{table_name}:#{record_name}") & 0x7FFFFFFF
    end
  end
end
