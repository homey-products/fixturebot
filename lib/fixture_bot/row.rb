# frozen_string_literal: true

module FixtureBot
  Row = Data.define(:table, :name, :literal_values, :association_refs, :tag_refs)
end
