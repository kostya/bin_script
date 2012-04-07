require 'rubygems'
require "bundler"
Bundler.setup

require 'rspec/core/rake_task'

task :default => :spec
RSpec::Core::RakeTask.new(:spec)

require 'rubygems/package_task'
require 'rubygems/specification'

spec = eval(File.read('bin_script.gemspec'))

Gem::PackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end