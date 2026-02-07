# frozen_string_literal: true

module FixtureBot
  module Inflections
    UNCOUNTABLES = %w[equipment information rice money species series fish sheep jeans police].freeze

    PLURALS = [
      [/s$/i, "s"],
      [/^(ax|test)is$/i, '\1es'],
      [/(octop|vir)us$/i, '\1i'],
      [/(alias|status)$/i, '\1es'],
      [/(bu)s$/i, '\1ses'],
      [/(buffal|tomat)o$/i, '\1oes'],
      [/([ti])um$/i, '\1a'],
      [/sis$/i, "ses"],
      [/(?:([^f])fe|([lr])f)$/i, '\1\2ves'],
      [/(hive)$/i, '\1s'],
      [/([^aeiouy]|qu)y$/i, '\1ies'],
      [/(x|ch|ss|sh)$/i, '\1es'],
      [/(matr|vert|append)ix|ex$/i, '\1ices'],
      [/([m|l])ouse$/i, '\1ice'],
      [/^(ox)$/i, '\1en'],
      [/(quiz)$/i, '\1zes'],
      [/$/, "s"]
    ].freeze

    SINGULARS = [
      [/s$/i, ""],
      [/(ss)$/i, '\1'],
      [/(n)ews$/i, '\1ews'],
      [/([ti])a$/i, '\1um'],
      [/((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)(sis|ses)$/i, '\1sis'],
      [/(^analy)(sis|ses)$/i, '\1sis'],
      [/([^f])ves$/i, '\1fe'],
      [/(hive)s$/i, '\1'],
      [/(tive)s$/i, '\1'],
      [/([lr])ves$/i, '\1f'],
      [/([^aeiouy]|qu)ies$/i, '\1y'],
      [/(s)eries$/i, '\1eries'],
      [/(m)ovies$/i, '\1ovie'],
      [/(x|ch|ss|sh)es$/i, '\1'],
      [/^(m|l)ice$/i, '\1ouse'],
      [/(bus)(es)?$/i, '\1'],
      [/(o)es$/i, '\1'],
      [/(shoe)s$/i, '\1'],
      [/(cris|test)(is|es)$/i, '\1is'],
      [/^(a)x[ie]s$/i, '\1xis'],
      [/(octop|vir)(us|i)$/i, '\1us'],
      [/(alias|status)(es)?$/i, '\1'],
      [/^(ox)en/i, '\1'],
      [/(vert|ind)ices$/i, '\1ex'],
      [/(matr)ices$/i, '\1ix'],
      [/(quiz)zes$/i, '\1'],
      [/(database)s$/i, '\1']
    ].freeze

    IRREGULARS = {
      "person" => "people",
      "man" => "men",
      "child" => "children",
      "sex" => "sexes",
      "move" => "moves",
      "zombie" => "zombies"
    }.freeze

    def singularize(word)
      result = word.to_s.dup
      return result if UNCOUNTABLES.include?(result.downcase)

      IRREGULARS.each do |singular, plural|
        return singular if result.downcase == plural
      end

      SINGULARS.each do |pattern, replacement|
        if result =~ pattern
          return result.sub(pattern, replacement)
        end
      end

      result
    end

    def pluralize(word)
      result = word.to_s.dup
      return result if UNCOUNTABLES.include?(result.downcase)

      IRREGULARS.each do |singular, plural|
        return plural if result.downcase == singular
      end

      PLURALS.each do |pattern, replacement|
        if result =~ pattern
          return result.sub(pattern, replacement)
        end
      end

      result
    end
  end
end
