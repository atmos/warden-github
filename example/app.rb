require 'sinatra'

module Example
  class App < Sinatra::Base
    enable  :sessions
    enable  :raise_errors
    disable :show_exceptions

    use Warden::Manager do |manager|
      manager.default_strategies :github
      manager.failure_app = BadAuthentication

      manager[:github_client_id]    = ENV['GITHUB_CLIENT_ID']     || 'ee9aa24b64d82c21535a'
      manager[:github_secret]       = ENV['GITHUB_CLIENT_SECRET'] || 'ed8ff0c54067aefb808dab1ca265865405d08d6f'

      manager[:github_scopes]       = ''
      manager[:github_oauth_domain] = ENV['GITHUB_OAUTH_DOMAIN'] || 'https://github.com'
      manager[:github_callback_url] = '/auth/github/callback'
    end

    helpers do
      def ensure_authenticated
        unless env['warden'].authenticate!
          throw(:warden)
        end
      end

      def user
        env['warden'].user
      end
    end

    get '/' do
      ensure_authenticated
      <<-EOS
      <h2>Hello There, #{user.name}!</h2>
      <h3>Rails Org Member: #{user.organization_member?('rails')}.</h3>
      <h3>Publicized Rails Org Member: #{user.publicized_organization_member?('rails')}.</h3>
      <h3>Rails Committer Team Member: #{user.team_member?(632)}.</h3>
      EOS
    end

    get '/redirect_to' do
      ensure_authenticated
      "Hello There, #{user.name}! return_to is working!"
    end

    get '/auth/github/callback' do
      ensure_authenticated
      redirect '/'
    end

    get '/logout' do
      env['warden'].logout
      "Peace!"
    end
  end

  class BadAuthentication < Sinatra::Base
    get '/unauthenticated' do
      status 403
      "Unable to authenticate, sorry bud."
    end
  end

  def self.app
    @app ||= Rack::Builder.new do
      run App
    end
  end
end
