$:.push File.expand_path("../lib", __FILE__)
require "version"

Gem::Specification.new do |s|
  s.name          = "rails-translate-models"
  s.version       = RailsTranslateModels::VERSION
  s.require_paths = ["lib"]
  s.authors       = ["Francesc Pla"]
  s.email         = "francesc@francesc.net"
  s.summary       = "Simple gem to translate multi-lingual content in Rails models"
  s.description   = "Simple gem to translate multi-lingual content in Rails models in separate tables for each model (modelname_translations)"
  s.homepage      = "http://github.com/francesc/rails-translate-models"
  s.license       = "MIT"
  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_dependency('rails', '>= 3.0')
  s.add_development_dependency('sqlite3')
  s.add_development_dependency('minitest')
end

