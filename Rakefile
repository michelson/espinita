#begin
#  require 'bundler/setup'
#rescue LoadError
#  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
#end


require 'rspec/core/rake_task'
require 'bundler'
Bundler::GemHelper.install_tasks

desc 'Default: run unit specs.'
task :default => :spec

desc 'Test the lazy_high_charts plugin.'
RSpec::Core::RakeTask.new('spec') do |t|
  t.pattern = FileList['spec/**/*_spec.rb']
end

require 'rdoc/task'
RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Espinita'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

#APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
#load 'rails/tasks/engine.rake'

