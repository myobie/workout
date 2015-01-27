# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'workout/version'

Gem::Specification.new do |spec|
  spec.name          = "workout"
  spec.version       = Workout::VERSION
  spec.authors       = ["Nathan Herald"]
  spec.email         = ["me@nathanherald.com"]
  spec.summary       = %q{Build simple workflow service objects.}
  spec.description   = %q{Make objects to represent and execute operations as steps, one by one, and know if it succeeded.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "activemodel"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
