lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'timeasure/version'

Gem::Specification.new do |spec|
  spec.name          = 'timeasure'
  spec.version       = Timeasure::VERSION
  spec.authors       = ['Eliav Lavi']
  spec.email         = ['eliav@riskified.com', 'eliavlavi@gmail.com']
  spec.summary       = 'Transparent method-level wrapper for profiling purposes'
  spec.description   = <<-DESCRIPTION
                          Timeasure is a Ruby gem that allows measuring the runtime of methods
                          without having to alter the code of the methods themselves.
                       DESCRIPTION
  spec.homepage      = 'https://github.com/riskified/timeasure'
  spec.license       = 'MIT'
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.start_with? 'spec/' }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ['lib', 'lib/timeasure', 'lib/timeasure/profiling']

  spec.required_ruby_version = '>= 2.1'
  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.6'
end
