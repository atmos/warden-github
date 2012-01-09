module Warden
  module Github
    module Oauth
      class Proxy
        attr_accessor :client_id, :secret, :scopes, :callback_url
        def initialize(client_id, secret, scopes, callback_url)
          @client_id, @secret, @scopes, @callback_url = client_id, secret, scopes, callback_url
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
                                         :site          => 'https://github.com',
                                         :token_url     => '/login/oauth/access_token',
                                         :authorize_url => '/login/oauth/authorize')
        end

        def api_for(code)
          client.auth_code.get_token(code, :redirect_uri => callback_url)
        end

        def authorize_url
          client.auth_code.authorize_url(
            :scope        => scopes,
            :redirect_uri => callback_url
          )
        end
      end
    end
  end
end
