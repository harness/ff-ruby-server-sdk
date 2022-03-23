# frozen_string_literal: true

system "sh scripts/openapi.sh lib/ff/ruby/server/generated"

require_relative "lib/ff/ruby/server/sdk/version"

Gem::Specification.new do |spec|

  spec.name = "ff-ruby-server-sdk"
  spec.version = Ff::Ruby::Server::Sdk::VERSION
  spec.authors = ["Milos Vasic"]
  spec.email = ["milos.vasic@harness.io"]

  spec.summary = "Harness is a feature management platform that helps teams to build better software and to test features quicker."
  spec.description = "Harness is a feature management platform that helps teams to build better software and to test features quicker."
  spec.homepage = "https://www.harness.io/"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/harness/ff-ruby-server-sdk"
  spec.metadata["changelog_uri"] = "https://github.com/harness/ff-ruby-server-sdk/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end

  spec.files += Dir['lib/ff/ruby/server/generated/lib/**/*.rb']

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }

  spec.require_paths = ["lib"]
  spec.require_paths += ["lib/ff/ruby/server/generated/lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
