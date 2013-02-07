require 'octokit'

module Warden
  module GitHub
    class User < Struct.new(:attribs, :token)
      ATTRIBUTES = %w[id login name gravatar_id email company].freeze

      def self.load(access_token)
        api = Octokit::Client.new(:oauth_token => access_token)
        data = Hash[api.user.to_hash.select { |k,_| ATTRIBUTES.include?(k) }]

        new(data, access_token)
      end

      def marshal_dump
        Hash[members.zip(values)]
      end

      def marshal_load(hash)
        hash.each { |k,v| send("#{k}=", v) }
      end

      ATTRIBUTES.each do |name|
        define_method(name) { attribs[name] }
      end

      # See if the user is a public member of the named organization
      #
      # name - the organization name
      #
      # Returns: true if the user is publicized as an org member
      def organization_public_member?(org_name)
        fetch_membership(:org_pub, org_name) do
          api.organization_public_member?(org_name, login)
        end
      end

      # Backwards compatibility:
      alias_method :publicized_organization_member?, :organization_public_member?

      # See if the user is a member of the named organization
      #
      # name - the organization name
      #
      # Returns: true if the user has access, false otherwise
      def organization_member?(org_name)
        fetch_membership(:org, org_name) do
          api.organization_member?(org_name, login)
        end
      end

      # See if the user is a member of the team id
      #
      # team_id - the team's id
      #
      # Returns: true if the user has access, false otherwise
      def team_member?(team_id)
        fetch_membership(:team, team_id) do
          # TODO: Use next line as method body once pengwynn/octokit#206 is public.
          # api.team_member?(team_id, login)

          begin
            # A user is only able to query for team members if they're a member.
            # Thus, if querying does succeed, they will be in the list and
            # checking the list won't be necessary.
            api.team_members(team_id)
            true
          rescue Octokit::NotFound
            false
          end
        end
      end

      # Access the GitHub API from Octokit
      #
      # Octokit is a robust client library for the GitHub API
      # https://github.com/pengwynn/octokit
      #
      # Returns a cached client object for easy use
      def api
        # Don't cache instance for now because of a ruby marshaling bug present
        # in MRI 1.9.3 (Bug #7627) that causes instance variables to be
        # marshaled even when explicitly specifying #marshal_dump.
        Octokit::Client.new(:login => login, :oauth_token => token)
      end

      private

      # Fetches a membership status by type (e.g. 'org') and id (e.g. 'github')
      # from cache. If no value is present, the block will be invoked and the
      # return value cached for subsequent calls.
      def fetch_membership(type, id)
        id = id.to_s if id.is_a?(Symbol)
        attribs['member'] ||= {}
        hash = attribs['member'][type.to_s] ||= {}

        if hash.include?(id)
          hash[id]
        else
          hash[id] = yield
        end
      end
    end
  end
end
