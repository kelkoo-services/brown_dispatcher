# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'brown_dispatcher/version'

Gem::Specification.new do |spec|
  spec.name          = "brown_dispatcher"
  spec.version       = BrownDispatcher::VERSION
  spec.authors       = ["ciscou"]
  spec.email         = ["francismpp@gmail.com"]
  spec.description   = %q{Delegate HTTP requests to another webservice than can actually handle them}
  spec.summary       = %q{Delegate HTTP requests to another webservice than can actually handle them}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
