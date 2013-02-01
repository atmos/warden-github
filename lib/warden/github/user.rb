require 'octokit'

module Warden
  module GitHub
    class User < Struct.new(:attribs, :token)
      def self.load(access_token)
        api = Octokit::Client.new(:oauth_token => access_token)

        new(api.user.to_hash, access_token)
      end

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
      def organization_public_member?(org_name)
        api.organization_public_member?(org_name, login)
      end

      # Backwards compatibility:
      alias_method :publicized_organization_member?, :organization_public_member?

      # See if the user is a member of the named organization
      #
      # name - the organization name
      #
      # Returns: true if the user has access, false otherwise
      def organization_member?(org_name)
        api.organization_member?(org_name, login)
      end

      # See if the user is a member of the team id
      #
      # team_id - the team's id
      #
      # Returns: true if the user has access, false otherwise
      def team_member?(team_id)
        # TODO: Use next line as method body once pengwynn/octokit#206 is public.
        # api.team_member?(team_id, login)

        # If the user is able to query the team member
        # A user is only able to query for team members if they're a member.
        # Thus, if querying does succeed, they will be in the list and checking
        # the list won't be necessary.
        api.team_members(team_id)

        true
      rescue Octokit::NotFound
        false
      end

      # Access the GitHub API from Octokit
      #
      # Octokit is a robust client library for the GitHub API
      # https://github.com/pengwynn/octokit
      #
      # Returns a cached client object for easy use
      def api
        @api ||= Octokit::Client.new(:login => login, :oauth_token => token)
      end
    end
  end
end
