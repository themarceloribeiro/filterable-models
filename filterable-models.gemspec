# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "filterable-models/version"

Gem::Specification.new do |s|
  s.name        = "filterable-models"
  s.version     = Filterable::Models::VERSION
  s.authors     = ["Marcelo Ribeiro"]
  s.email       = ["me@marceloribeiro.us"]
  s.homepage    = ""
  s.summary     = %q{Filter functionality for Rails models}
  s.description = %q{Start filtering your models and adding a filter form to your scaffolds pretty fast}

  s.rubyforge_project = "filterable-models"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
