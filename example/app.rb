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
      manager[:github_callback_url] = '/login'
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
      if user
        <<-EOS
        <h2>Hello #{user.name}!</h2>
        <ul>
          <li><a href='/profile'>View profile</a></li>
          <li><a href='/logout'>Sign out</a></li>
        </ul>
        EOS
      else
        <<-EOS
        <h2>Hello stranger!</h2>
        <ul>
          <li><a href='/profile'>View profile</a> (implicit sign in)</li>
          <li><a href='/login'>Sign in</a> (explicit sign in)</li>
        </ul>
        EOS
      end
    end

    get '/profile' do
      ensure_authenticated
      <<-EOS
      <h2>Hello #{user.name}!</h2>
      <ul>
        <li><a href='/'>Home</a></li>
        <li><a href='/logout'>Sign out</a></li>
      </ul>
      <h3>Profile</h3>
      <h4>Rails Org Member: #{user.organization_member?('rails')}.</h4>
      <h4>Publicized Rails Org Member: #{user.publicized_organization_member?('rails')}.</h4>
      <h4>Rails Committer Team Member: #{user.team_member?(632)}.</h4>
      EOS
    end

    get '/login' do
      ensure_authenticated
      redirect '/'
    end

    get '/logout' do
      env['warden'].logout
      redirect '/'
    end

    get '/debug' do
      content_type :text
      env['rack.session'].to_yaml
    end
  end

  class BadAuthentication < Sinatra::Base
    get '/unauthenticated' do
      status 403
      <<-EOS
      <h2>Unable to authenticate, sorry bud.</h2>
      <p>#{env['warden'].message}</p>
      EOS
    end
  end

  def self.app
    @app ||= Rack::Builder.new do
      run App
    end
  end
end
