# frozen_string_literal: true

require "fixturebot/rails"
require "tmpdir"

RSpec.describe FixtureBot::Rails, ".compile" do
  before do
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

    ActiveRecord::Schema.define(version: 2024_01_01_000000) do
      create_table "users", force: :cascade do |t|
        t.string "name"
        t.string "email"
        t.timestamps
      end

      create_table "posts", force: :cascade do |t|
        t.string "title"
        t.text "body"
        t.integer "author_id"
        t.timestamps
      end

      add_foreign_key "posts", "users", column: "author_id"
    end
  end

  after do
    ActiveRecord::Base.connection_pool.disconnect!
  end

  it "compiles YAML fixture files from a DSL file" do
    Dir.mktmpdir do |tmpdir|
      fixtures_file = File.join(tmpdir, "fixtures.rb")
      output_dir = File.join(tmpdir, "fixtures")

      File.write(fixtures_file, <<~RUBY)
        FixtureBot.define do
          user :alice do
            name "Alice"
            email "alice@example.com"
          end

          user :bob do
            name "Bob"
            email "bob@example.com"
          end

          post :hello do
            title "Hello World"
            body "First post"
            author :alice
          end
        end
      RUBY

      described_class.compile(fixtures_file: fixtures_file, output_dir: output_dir)

      users_yaml = YAML.load_file(File.join(output_dir, "users.yml"))
      expect(users_yaml.keys).to contain_exactly("alice", "bob")
      expect(users_yaml["alice"]["name"]).to eq("Alice")
      expect(users_yaml["alice"]["email"]).to eq("alice@example.com")
      expect(users_yaml["bob"]["name"]).to eq("Bob")

      posts_yaml = YAML.load_file(File.join(output_dir, "posts.yml"))
      expect(posts_yaml.keys).to contain_exactly("hello")
      expect(posts_yaml["hello"]["title"]).to eq("Hello World")
    end
  end

  it "skips empty tables" do
    Dir.mktmpdir do |tmpdir|
      fixtures_file = File.join(tmpdir, "fixtures.rb")
      output_dir = File.join(tmpdir, "fixtures")

      File.write(fixtures_file, <<~RUBY)
        FixtureBot.define do
          user :alice do
            name "Alice"
            email "alice@example.com"
          end
        end
      RUBY

      described_class.compile(fixtures_file: fixtures_file, output_dir: output_dir)

      expect(File.exist?(File.join(output_dir, "users.yml"))).to be true
      expect(File.exist?(File.join(output_dir, "posts.yml"))).to be false
    end
  end

  it "returns early when fixtures file does not exist" do
    Dir.mktmpdir do |tmpdir|
      output_dir = File.join(tmpdir, "fixtures")

      described_class.compile(
        fixtures_file: File.join(tmpdir, "nonexistent.rb"),
        output_dir: output_dir
      )

      expect(Dir.exist?(output_dir)).to be false
    end
  end

  describe ".detect_fixtures_files" do
    it "finds a single spec/fixtures.rb" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.mkdir_p("spec")
          File.write("spec/fixtures.rb", "")

          files = described_class.send(:detect_fixtures_files)
          expect(files).to eq(["spec/fixtures.rb"])
        end
      end
    end

    it "finds spec/fixtures/*.rb directory files" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.mkdir_p("spec/fixtures")
          File.write("spec/fixtures/posts.rb", "")
          File.write("spec/fixtures/users.rb", "")

          files = described_class.send(:detect_fixtures_files)
          expect(files).to eq(["spec/fixtures/posts.rb", "spec/fixtures/users.rb"])
        end
      end
    end

    it "loads single file first then directory files alphabetically" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.mkdir_p("spec/fixtures")
          File.write("spec/fixtures.rb", "")
          File.write("spec/fixtures/posts.rb", "")
          File.write("spec/fixtures/users.rb", "")

          files = described_class.send(:detect_fixtures_files)
          expect(files).to eq([
            "spec/fixtures.rb",
            "spec/fixtures/posts.rb",
            "spec/fixtures/users.rb"
          ])
        end
      end
    end

    it "prefers test/ over spec/ when test/ exists" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.mkdir_p("test")
          File.write("test/fixtures.rb", "")

          files = described_class.send(:detect_fixtures_files)
          expect(files).to eq(["test/fixtures.rb"])
        end
      end
    end

    it "returns empty array when no fixtures found" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          files = described_class.send(:detect_fixtures_files)
          expect(files).to eq([])
        end
      end
    end
  end

  describe ".detect_output_dir" do
    it "derives spec/fixtures from spec/fixtures.rb" do
      result = described_class.send(:detect_output_dir, ["spec/fixtures.rb"])
      expect(result).to eq("spec/fixtures")
    end

    it "derives spec/fixtures from spec/fixtures/*.rb files" do
      result = described_class.send(:detect_output_dir, ["spec/fixtures/users.rb", "spec/fixtures/posts.rb"])
      expect(result).to eq("spec/fixtures")
    end

    it "derives test/fixtures from test/fixtures.rb" do
      result = described_class.send(:detect_output_dir, ["test/fixtures.rb"])
      expect(result).to eq("test/fixtures")
    end

    it "falls back to stripping .rb for non-standard paths" do
      result = described_class.send(:detect_output_dir, ["/custom/path/my_fixtures.rb"])
      expect(result).to eq("/custom/path/my_fixtures")
    end

    it "defaults to spec/fixtures for empty array" do
      result = described_class.send(:detect_output_dir, [])
      expect(result).to eq("spec/fixtures")
    end
  end

  describe ".resolve_fixtures_files" do
    it "wraps a single string in an array" do
      Dir.mktmpdir do |tmpdir|
        path = File.join(tmpdir, "fixtures.rb")
        File.write(path, "")

        files = described_class.send(:resolve_fixtures_files, path)
        expect(files).to eq([path])
      end
    end

    it "passes through an array" do
      Dir.mktmpdir do |tmpdir|
        path1 = File.join(tmpdir, "a.rb")
        path2 = File.join(tmpdir, "b.rb")
        File.write(path1, "")
        File.write(path2, "")

        files = described_class.send(:resolve_fixtures_files, [path1, path2])
        expect(files).to eq([path1, path2])
      end
    end

    it "filters out non-existent files from explicit paths" do
      Dir.mktmpdir do |tmpdir|
        existing = File.join(tmpdir, "exists.rb")
        File.write(existing, "")

        files = described_class.send(:resolve_fixtures_files, [existing, File.join(tmpdir, "nope.rb")])
        expect(files).to eq([existing])
      end
    end
  end

  it "compiles from multiple fixture files" do
    Dir.mktmpdir do |tmpdir|
      users_file = File.join(tmpdir, "users.rb")
      posts_file = File.join(tmpdir, "posts.rb")
      output_dir = File.join(tmpdir, "fixtures")

      File.write(users_file, <<~RUBY)
        FixtureBot.define do
          user :alice do
            name "Alice"
            email "alice@example.com"
          end
        end
      RUBY

      File.write(posts_file, <<~RUBY)
        FixtureBot.define do
          post :hello do
            title "Hello World"
            body "First post"
            author :alice
          end
        end
      RUBY

      described_class.compile(
        fixtures_file: [users_file, posts_file],
        output_dir: output_dir
      )

      users_yaml = YAML.load_file(File.join(output_dir, "users.yml"))
      expect(users_yaml.keys).to contain_exactly("alice")
      expect(users_yaml["alice"]["name"]).to eq("Alice")

      posts_yaml = YAML.load_file(File.join(output_dir, "posts.yml"))
      expect(posts_yaml.keys).to contain_exactly("hello")
      expect(posts_yaml["hello"]["title"]).to eq("Hello World")
    end
  end

  it "merges defaults from a base file with records from domain files" do
    Dir.mktmpdir do |tmpdir|
      base_file = File.join(tmpdir, "base.rb")
      users_file = File.join(tmpdir, "users.rb")
      output_dir = File.join(tmpdir, "fixtures")

      File.write(base_file, <<~RUBY)
        FixtureBot.define do
          user.email { |fixture| "\#{fixture.key}@example.com" }
        end
      RUBY

      File.write(users_file, <<~RUBY)
        FixtureBot.define do
          user :alice do
            name "Alice"
          end

          user :bob do
            name "Bob"
          end
        end
      RUBY

      described_class.compile(
        fixtures_file: [base_file, users_file],
        output_dir: output_dir
      )

      users_yaml = YAML.load_file(File.join(output_dir, "users.yml"))
      expect(users_yaml["alice"]["name"]).to eq("Alice")
      expect(users_yaml["alice"]["email"]).to eq("alice@example.com")
      expect(users_yaml["bob"]["email"]).to eq("bob@example.com")
    end
  end

  it "allows later files to override defaults from earlier files" do
    Dir.mktmpdir do |tmpdir|
      base_file = File.join(tmpdir, "base.rb")
      override_file = File.join(tmpdir, "override.rb")
      output_dir = File.join(tmpdir, "fixtures")

      File.write(base_file, <<~RUBY)
        FixtureBot.define do
          user.email { "default@example.com" }
        end
      RUBY

      File.write(override_file, <<~RUBY)
        FixtureBot.define do
          user.email { "overridden@example.com" }

          user :alice do
            name "Alice"
          end
        end
      RUBY

      described_class.compile(
        fixtures_file: [base_file, override_file],
        output_dir: output_dir
      )

      users_yaml = YAML.load_file(File.join(output_dir, "users.yml"))
      expect(users_yaml["alice"]["email"]).to eq("overridden@example.com")
    end
  end
end
