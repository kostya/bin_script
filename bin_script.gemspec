# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + "/lib/bin_script/version"

Gem::Specification.new do |s|
  s.name = %q{bin_script}
  s.version = BinScript::VERSION

  s.authors = ["Makarchev Konstantin", "Lifshits Dmitry"]
  s.autorequire = %q{init}

  s.description = s.summary = \
    %q{Gem for easy writing and executing scripts in Rails Application. For my purposes much better than Rake, Thor and Rails Runner.}

  s.email = %q{kostya27@gmail.com}
  s.homepage = %q{http://github.com/kostya/bin_script}
  s.license = "MIT"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'activesupport'
  s.add_dependency 'rails'

  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"

end
