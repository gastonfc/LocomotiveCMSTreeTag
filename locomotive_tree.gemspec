# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'locomotive_tree/version'

Gem::Specification.new do |spec|
  spec.name          = "locomotive_tree"
  spec.version       = LocomotiveTree::VERSION
  spec.authors       = ["Gastón Fernández"]
  spec.email         = ["gaston.fernandez@pyxis.com.uy"]
  spec.summary       = %q{Add a new tag 'tree' to Locomotive CMS}
  spec.description   = %q{Add a new tag 'tree' to Locomotive CMS}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'locomotive_liquid'
  spec.add_dependency 'mongoid'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency 'rails', '3.2.19'
  spec.add_development_dependency 'locomotive_cms', '~> 2.5.6' # , :require => 'locomotive/engine'
  spec.add_development_dependency 'tigerlily-solid' #, :require => 'solid'
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
