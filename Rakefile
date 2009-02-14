require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rcov/rcovtask'

task :default => ['test:unit','test:spec','test:coverage']

namespace :test do
  Rake::TestTask.new(:unit) do |t|
    t.libs << 'test'
    t.warning = true
    t.test_files = FileList['test/test_*.rb']
  end

  Rcov::RcovTask.new(:coverage) do |t|
    t.rcov_opts << '--exclude' << '/gems/,/ruby-git\/lib/'
    t.libs << 'test'
    t.warning = false
    t.verbose = true
    t.test_files = FileList['test/test_*.rb','test/spec_*.rb']
  end

  Rake::TestTask.new(:spec) do |t|
    t.libs << 'test'
    t.warning = false # Sinatra warnings
    t.test_files = FileList['test/spec_*.rb']
  end
end

desc 'Remove wiki folder'
task :clean do |t|
  FileUtils.rm_rf '.wiki'
  FileUtils.rm_rf 'doc'
  FileUtils.rm_rf 'coverage'
end

desc 'Generate AkaPortal documentation'
Rake::RDocTask.new(:doc) { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = 'Git-Wiki Documentation'
  rdoc.options << '--line-numbers' << '--inline-source' << '--diagram'
  rdoc.options << '--charset' << 'utf-8'
  rdoc.rdoc_files.include('**/*.rb')
}
