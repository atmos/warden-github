# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require 'warden-github/version'

Gem::Specification.new do |s|
  s.name        = "warden-github"
  s.version     = Warden::Github::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Corey Donohoe"]
  s.email       = ["atmos@atmos.org"]
  s.homepage    = "http://github.com/atmos/warden-github"
  s.summary     = "A warden strategy for easy oauth integration with github"
  s.description = s.summary

  s.rubyforge_project = "warden-github"

  s.add_dependency "json",   "~>1.5"
  s.add_dependency "warden", "~>1.0"
  s.add_dependency "oauth2", "~>0.5.2"
  s.add_dependency "octokit", "~>1.4.0"
  s.add_dependency "rest-client", "~>1.6.1"
  s.add_dependency "yajl-ruby",     "~>1.1"

  s.add_development_dependency "rack",      "~>1.4.0"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec",     "~>2.8.0"
  s.add_development_dependency "webrat"
  s.add_development_dependency "sinatra"
  s.add_development_dependency "shotgun"
  s.add_development_dependency "addressable", "~>2.2.0"
  s.add_development_dependency "rack-test",   "~>0.5.3"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
