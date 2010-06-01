Warden::Strategies.add(:github) do
  # Need to make sure that we have a pure representation of the query string.
  # Rails adds an "action" parameter which causes the openid gem to error
  def params
    @params ||= Rack::Utils.parse_query(request.query_string)
  end

  def authenticate!
    if params['code']
      begin
        access_token = oauth_client.web_server.get_access_token(params['code'], :redirect_uri => callback_url)
        user = JSON.parse(access_token.get('/api/v2/json/user/show'))
        success!(Warden::Github::Oauth::User.new(user['user'], access_token.token))
      rescue OAuth2::HTTPError
        %(<p>Outdated ?code=#{params[:code]}:</p><p>#{$!}</p><p><a href="/auth/github">Retry</a></p>)
      end
    else
      url = oauth_client.web_server.authorize_url(
        :scope        => 'email,offline_access',
        :redirect_uri => callback_url
      )
      throw(:halt, [ 302, {'Location' => url}, [ ]])
    end
  end

  private
  def oauth_client
    OAuth2::Client.new(env['warden'].config[:github_client_id],
                       env['warden'].config[:github_secret],
                       :site              => 'https://github.com',
                       :authorize_path    => '/login/oauth/authorize',
                       :access_token_path => '/login/oauth/access_token')
  end

  def callback_url
     absolute_url(request, env['warden'].config[:github_callback_url])
  end

  def absolute_url(request, suffix = nil)
    port_part = case request.scheme
                when "http"
                  request.port == 80 ? "" : ":#{request.port}"
                when "https"
                  request.port == 443 ? "" : ":#{request.port}"
                end
    "#{request.scheme}://#{request.host}#{port_part}#{suffix}"
  end
end
