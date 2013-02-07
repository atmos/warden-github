ENV['RACK_ENV'] ||= 'development'

begin
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  require "rubygems"
  require "bundler"
  Bundler.setup
end

begin
  require 'debugger'
rescue LoadError
  require 'ruby-debug'
end

require 'warden/github'

if ENV['MULTI_SCOPE_APP']
  require File.expand_path('../example/multi_scope_app', __FILE__)
else
  require File.expand_path('../example/simple_app', __FILE__)
end

run Example.app
