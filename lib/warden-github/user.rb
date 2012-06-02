require 'yajl'
require 'rest-client'

module Warden
  module Github
    module Oauth
      class User < Struct.new(:attribs, :token)
        def login
          attribs['login']
        end

        def name
          attribs['name']
        end

        def gravatar_id
          attribs['gravatar_id']
        end

        def email
          attribs['email']
        end

        def company
          attribs['company']
        end

        # See if the user is a public member of the named organization
        #
        # name - the organization name
        #
        # Returns: true if the user is publicized as an org member
        def publicized_organization_member?(org_name)
          members = github_request("orgs/#{org_name}/public_members")
          members.map { |org| org["login"] }.include?(login)
        rescue RestClient::Forbidden, RestClient::Unauthorized, RestClient::ResourceNotFound => e
          false
        end

        # See if the user is a member of the named organization
        #
        # name - the organization name
        #
        # Returns: true if the user has access, false otherwise
        def organization_member?(org_name)
          orgs = github_request("orgs/#{org_name}/members")
          orgs.map { |org| org["login"] }.include?(login)
        rescue RestClient::Forbidden, RestClient::Unauthorized, RestClient::ResourceNotFound => e
          false
        end

        # See if the user is a member of the team id
        #
        # team_id - the team's id
        #
        # Returns: true if the user has access, false otherwise
        def team_member?(team_id)
          members = github_request("teams/#{team_id}/members")
          members.map { |user| user["login"] }.include?(login)
        rescue RestClient::Forbidden, RestClient::Unauthorized, RestClient::ResourceNotFound => e
          false
        end

        # Send a V3 API GET request to path and parse the response body
        #
        # path - the path on api.github.com to hit
        # params - extra params for calling the api
        #
        # Returns a parsed JSON response
        #
        # Examples
        #   github_request("/user")
        #   # => { 'login' => 'atmos', ... }
        #
        #   github_request("/user/repos", {:page => 2})
        #   # => [ { 'name' => 'gollum' ... } ]
        def github_request(path, params = {})
          Yajl.load(github_raw_request(path, params))
        end

        # Send a V3 API GET request to path
        #
        # path - the path on api.github.com to hit
        #
        # Returns a rest client response object
        #
        # Examples
        #   github_raw_request("/user")
        #   # => RestClient::Response
        #
        #   github_raw_request("/user/repos", {:page => 3})
        #   # => RestClient::Response
        def github_raw_request(path, params = {})
          RestClient.get("#{github_api_uri}/#{path}", :params => params.merge({ :access_token => token }), :accept => :json)
        end

        private
        def github_api_uri
          if ENV['GITHUB_OAUTH_API_DOMAIN']
            ENV['GITHUB_OAUTH_API_DOMAIN']
          else
            "https://api.github.com"
          end
        end
      end
    end
  end
end
