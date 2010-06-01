require 'warden'
require 'oauth2'
require 'json'

module Warden
  module Github
    class GithubMisconfiguredError < StandardError; end
  end
end

require 'warden-github/user'
require 'warden-github/version'
require 'warden-github/strategy'
