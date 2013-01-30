module Warden
  module GitHub
    class Strategy < ::Warden::Strategies::Base
      SESSION_KEY = 'warden.github.oauth'

      # The first time this is called, the flow gets set up, stored in the
      # session and the user gets redirected to GitHub to perform the login.
      #
      # When this is called a second time, the flow gets evaluated, the code
      # gets exchanged for a token, and the user gets loaded and passed to
      # warden.
      #
      # If anything goes wrong, the flow is aborted and reset, and warden gets
      # notified about the failure.
      def authenticate!
        if in_flow?
          finish_flow!
        else
          begin_flow!
        end
      end

      private

      def begin_flow!
        setup_flow
        redirect!(authorize_url)
        throw(:warden)
      end

      def finish_flow!
        validate_flow!
        teardown_flow
        success!(load_user)
      end

      def abort_flow!(message)
        teardown_flow
        fail!(message)
        throw(:warden)
      end

      def setup_flow
        custom_session['state'] = state
      end

      def teardown_flow
        session.delete(SESSION_KEY)
      end

      def in_flow?
        !custom_session.empty? && params['state'] && params['code']
      end

      def validate_flow!
        abort_flow!('State mismatch')  unless valid_state?
      end

      def valid_state?
        params['state'] == custom_session['state']
      end

      def custom_session
        session[SESSION_KEY] ||= {}
      end

      def load_user
        api = api_for(params['code'])
        user_info = Yajl.load(user_info_for(api.token))
        user_info.delete('bio') # Delete bio, as it can easily make the session cookie too long.
        User.new(user_info, api.token)
      rescue OAuth2::Error
        abort_flow!('Invalid code')
      end

      def state
        oauth_proxy.state
      end

      def oauth_client
        oauth_proxy.client
      end

      def authorize_url
        oauth_proxy.authorize_url
      end

      def api_for(code)
        oauth_proxy.api_for(code)
      end

      def oauth_proxy
        @oauth_proxy ||= Warden::GitHub::Proxy.new(env['warden'].config[:github_client_id],
                                                   env['warden'].config[:github_secret],
                                                   env['warden'].config[:github_scopes],
                                                   env['warden'].config[:github_oauth_domain],
                                                   callback_url)
      end

      def user_info_for(token)
        @user_info ||= RestClient.get(github_api_uri + "/user", :params => {:access_token => token})
      end

      def callback_url
        absolute_url(request, callback_path, env['HTTP_X_FORWARDED_PROTO'])
      end

      def callback_path
        env['warden'].config[:github_callback_url] || request.path
      end

      def absolute_url(request, suffix = nil, proto = "http")
        port_part = case request.scheme
                    when "http"
                      request.port == 80 ? "" : ":#{request.port}"
                    when "https"
                      request.port == 443 ? "" : ":#{request.port}"
                    end

        proto = "http" if proto.nil?
        "#{proto}://#{request.host}#{port_part}#{suffix}"
      end

      def github_api_uri
        if ENV['OCTOKIT_API_ENDPOINT']
          ENV['OCTOKIT_API_ENDPOINT']
        else
          "https://api.github.com"
        end
      end
    end
  end
end

Warden::Strategies.add(:github, Warden::GitHub::Strategy)
