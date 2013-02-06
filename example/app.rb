require 'sinatra'
require 'yajl/json_gem'

module Example
  class App < Sinatra::Base
    enable  :sessions
    enable  :raise_errors
    disable :show_exceptions


    GITHUB_CONFIG = {
      :client_id     => ENV['GITHUB_CLIENT_ID']     || 'test_client_id',
      :client_secret => ENV['GITHUB_CLIENT_SECRET'] || 'test_client_secret',
      :scope         => 'user'
    }

    use Warden::Manager do |config|
      config.failure_app = BadAuthentication
      config.default_strategies :github
      config.scope_defaults :default, :config => GITHUB_CONFIG
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
      <h4>Publicized Rails Org Member: #{user.organization_public_member?('rails')}.</h4>
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
