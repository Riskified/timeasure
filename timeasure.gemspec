lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'timeasure/version'

Gem::Specification.new do |spec|
  spec.name          = 'timeasure'
  spec.version       = Timeasure::VERSION
  spec.authors       = ['Eliav Lavi']
  spec.email         = ['eliav@riskified.com']
  spec.summary       = 'Transparent method-level wrapper for profiling purposes'
  spec.description   = <<-DESCRIPTION
                          Timeasure allows you to declare tracked methods to be measured
                          transparently upon each call. Measured calls are then reported according
                          to a configurable proc of your liking.
                       DESCRIPTION
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.0'
  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'coveralls'
end
