#!/usr/bin/env rackup

ENV['RACK_ENV'] = env

path = File.expand_path(File.dirname(__FILE__))

$: << File.join(path, 'lib')
require 'wiki/app'

config_file = if ENV['WIKI_CONFIG']
  ENV['WIKI_CONFIG']
else
  File.join(path, 'config.yml')
end

config = if File.file?(config_file)
  YAML.load_file(config_file)
else
  { 'title'        => 'Git-Wiki',
    'repository'   => File.join(path, '.wiki', 'repository'),
    'workspace'    => File.join(path, '.wiki', 'workspace'),
    'store'        => File.join(path, '.wiki', 'store.yml'),
    'cache'        => File.join(path, '.wiki', 'cache'),
    'loglevel'     => 'INFO',
    'logfile'      => File.join(path, '.wiki', 'log'),
    'default_mime' => 'text/x-creole',
    'main_page'    => 'Home',
    'rewrite_base' => nil,
    'profiling'    => false,
  }
end

require 'rack/path_info'
use Rack::PathInfo

if config['profiling']
  require 'rack/contrib'
  use Rack::Profiler, :printer => :graph
end

if !config['rewrite_base'].blank?
  require 'rack/rewrite'
  use Rack::Rewrite, :base => config['rewrite_base']
end

# FIXME: Problem with fastcgi handler
if server == 'fastcgi'
  options.delete :File
  options.delete :Port
end

use Rack::Session::Pool
Wiki::App.set :config, config
run Wiki::App

