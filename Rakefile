require 'rspec/core/rake_task'
require 'bundler'
require "bundler/setup"

require 'bundler/gem_tasks'
require 'appraisal'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks

desc 'Default: run unit tests.'
task :default => [:all]

desc 'Test the plugin under all supported Rails versions.'
task :all => ["appraisal:cleanup", "appraisal:install"] do
  exec('rake appraisal spec')
end

desc 'Test the espinita plugin.'
RSpec::Core::RakeTask.new(:spec)

require 'rdoc/task'
RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Espinita'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end