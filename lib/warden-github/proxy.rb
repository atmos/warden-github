module Warden
  module Github
    module Oauth
      class Proxy
        attr_accessor :client_id, :secret, :scopes, :oauth_domain, :callback_url
        def initialize(client_id, secret, scopes, oauth_domain, callback_url)
          @client_id, @secret, @scopes, @oauth_domain, @callback_url = client_id, secret, scopes, oauth_domain, callback_url
        end

        def ssl_options
          ca_file = "/usr/lib/ssl/certs/ca-certificates.crt"
          if File.exists?(ca_file)
            { :ca_file => ca_file }
          else
            { :ca_file => ''}
          end
        end

        def client
          @client ||= OAuth2::Client.new(@client_id, @secret,
                                         :ssl           => ssl_options,
                                         :site          => oauth_domain,
                                         :token_url     => '/login/oauth/access_token',
                                         :authorize_url => '/login/oauth/authorize')
        end

        def api_for(code)
          client.auth_code.get_token(code, :redirect_uri => callback_url)
        end

        def state
          @state ||= Digest::SHA1.hexdigest(rand(36**8).to_s(36))
        end

        def authorize_url
          client.auth_code.authorize_url(
            :state        => state,
            :scope        => scopes,
            :redirect_uri => callback_url
          )
        end
      end
    end
  end
end
