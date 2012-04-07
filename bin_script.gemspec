# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + "/lib/bin_script/version"

Gem::Specification.new do |s|
  s.name = %q{bin_script}
  s.version = BinScript::VERSION

  s.authors = ["Lifshits Dmitry", "Makarchev Konstantin"]
  s.autorequire = %q{init}
  
  s.description = %q{Easy writing and executing bins (espesually for crontab or god) in Rails project}
  
  s.summary = %q{Easy writing and executing bins (espesually for crontab or god) in Rails project
For my purposes much better than Rake, Thor and Rails Runner}

  s.email = %q{kostya27@gmail.com}
  s.homepage = %q{http://github.com/kostya/bin_script}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'activesupport', ">=2.3.2"  
  s.add_development_dependency "rspec"
  
end