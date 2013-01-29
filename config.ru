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
require File.expand_path('../example/app', __FILE__)

run Example.app
