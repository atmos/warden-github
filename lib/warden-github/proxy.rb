module Warden
  module Github
    module Oauth
      class Proxy
        attr_accessor :client_id, :secret, :scopes, :callback_url
        def initialize(client_id, secret, scopes, callback_url)
          @client_id, @secret, @scopes, @callback_url = client_id, secret, scopes, callback_url
        end

        def client
          @client ||= OAuth2::Client.new(@client_id, @secret,
                                         :site              => 'https://github.com',
                                         :authorize_path    => '/login/oauth/authorize',
                                         :access_token_path => '/login/oauth/access_token')
        end

        def access_token_for(code)
          web_server.get_access_token(code, :redirect_uri => callback_url)
        end

        def authorize_url
          web_server.authorize_url(
            :scope        => scopes,
            :redirect_uri => callback_url
          )
        end

        def web_server
          client.web_server
        end
      end
    end
  end
end
