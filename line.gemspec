# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "line/version"

Gem::Specification.new do |s|
  s.name        = "line"
  s.version     = Line::VERSION
  s.authors     = ["Josh Cheek"]
  s.email       = ["josh.cheek@gmail.com"]
  s.homepage    = "https://github.com/JoshCheek/surrogate"
  s.summary     = %q{Command line tool to filter lines of input based on index.}
  s.description = %q{Command line tool to filter lines of input based on index.}

  s.rubyforge_project = "line"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  s.add_development_dependency "surrogate"
end
