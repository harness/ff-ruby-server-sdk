# frozen_string_literal: true

system "sh scripts/openapi.sh lib/ff/ruby/server/generated"

require_relative "lib/ff/ruby/server/sdk/version"

Gem::Specification.new do |spec|

  spec.name = "ff-ruby-server-sdk"
  spec.version = Ff::Ruby::Server::Sdk::VERSION
  spec.authors = ["Miloš Vasić, cyr.: Милош Васић"]
  spec.email = ["support@harness.io"]

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
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)}) || f.start_with?("ruby_on_rails_example")
    end
  end

  spec.files += Dir['lib/ff/ruby/server/generated/lib/**/*.rb']

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }

  spec.require_paths = ["lib"]
  spec.require_paths += ["lib/ff/ruby/server/generated/lib"]

  spec.add_dependency "rake", "~> 13.0"
  spec.add_dependency "minitest", "~> 5.0"
  spec.add_dependency "standard", "~> 1.3"

  spec.add_dependency "rufus-scheduler", "3.8.1"
  spec.add_dependency "libcache", "0.4.2"
  spec.add_dependency "jwt", "2.3.0"
  spec.add_dependency "moneta", "1.4.2"

  spec.add_dependency "rest-client", "2.1.0"

  spec.add_dependency "concurrent-ruby", "1.1.10"

  spec.add_dependency "murmurhash3", "0.1.6"

  spec.add_dependency "typhoeus", '~> 1.0', '>= 1.0.1'
end
