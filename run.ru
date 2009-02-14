#!/usr/bin/env rackup
require 'wiki/app'

path = File.expand_path(File.dirname(__FILE__))
config_file = File.join(path, 'config.yml')
config = if File.exists?(config_file)
  YAML.load_file(config_file)
else
  { 'title'        => 'Git-Wiki',
    'repository'   => File.join(path, '.wiki', 'repository'),
    'workspace'    => File.join(path, '.wiki', 'workspace'),
    'store'        => File.join(path, '.wiki', 'store.yml'),
    'cache'        => File.join(path, '.wiki', 'cache'),
    'loglevel'     => 'INFO',
    'logfile'      => File.join(path, '.wiki', 'log'),
    'default_mime' => 'text/x-creole'
  }
end

use Rack::Session::Pool
Wiki::App.set :config, config
run Wiki::App
