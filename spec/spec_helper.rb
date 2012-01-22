Bundler.require(:default, :runtime, :test)

require File.join(File.dirname(__FILE__), '..', 'lib', 'warden-github')
require File.join(File.dirname(__FILE__), 'app')
require 'rack/test'
require 'webrat'

require 'pp'

Webrat.configure do |config|
  config.mode = :rack
  config.application_port = 4567
end

RSpec.configure do |config|
  config.include(Rack::Test::Methods)
  config.include(Webrat::Methods)
  config.include(Webrat::Matchers)

  config.before(:each) do
  end

  def app
    Example.app
  end
end
