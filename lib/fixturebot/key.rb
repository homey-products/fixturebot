# frozen_string_literal: true

require "zlib"
require "active_support/core_ext/digest/uuid"

module FixtureBot
  module Key
    def self.generate(table_name, record_name)
      Zlib.crc32("#{table_name}:#{record_name}") & 0x7FFFFFFF
    end

    def self.generate_uuid(table_name, record_name)
      Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "fixturebot:#{table_name}:#{record_name}")
    end
  end
end
