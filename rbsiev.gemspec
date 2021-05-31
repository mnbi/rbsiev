# frozen_string_literal: true

require_relative "lib/rbsiev/version"

Gem::Specification.new do |spec|
  spec.name          = "rbsiev"
  spec.version       = Rbsiev::VERSION
  spec.authors       = ["mnbi"]
  spec.email         = ["mnbi@users.noreply.github.com"]

  spec.summary       = "SICP evaluator in Ruby"
  spec.description   = "An evaluator of Scheme language written in Ruby, which is implemented in SICP Chater 4."
  spec.homepage      = "https://github.com/mnbi/rbsiev"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mnbi/rbsiev"
  spec.metadata["changelog_uri"] = "https://github.com/mnbi/rbsiev/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rbscmlex", ">= 0.1.3"
  spec.add_dependency "rubasteme", ">= 0.1.4"
end
