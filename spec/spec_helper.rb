require 'simplecov'
SimpleCov.start do
  add_filter '/spec'
  add_filter '/example'
end

require 'warden/github'
require File.expand_path('../../example/simple_app', __FILE__)
require 'rack/test'
require 'addressable/uri'
require 'webmock/rspec'

RSpec.configure do |config|
  config.include(Rack::Test::Methods)

  def app
    Example.app
  end
end
