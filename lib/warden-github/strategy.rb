Warden::Strategies.add(:github) do
  # Need to make sure that we have a pure representation of the query string.
  # Rails adds an "action" parameter which causes the openid gem to error
  def params
    @params ||= Rack::Utils.parse_query(request.query_string)
  end

  def authenticate!
    if(params['code'] && params['state'] &&
       env['rack.session']['github_oauth_state'] &&
       env['rack.session']['github_oauth_state'].size > 0 &&
       params['state'] == env['rack.session']['github_oauth_state'])
      begin
        api = api_for(params['code'])

        success!(Warden::Github::Oauth::User.new(Yajl.load(user_info_for(api.token)), api.token))
      rescue OAuth2::Error
        %(<p>Outdated ?code=#{params['code']}:</p><p>#{$!}</p><p><a href="/auth/github">Retry</a></p>)
      end
    else
      env['rack.session']['github_oauth_state'] = state
      env['rack.session']['return_to'] = env['REQUEST_URI']
      throw(:warden, [ 302, {'Location' => authorize_url}, [ ]])
    end
  end

  private

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
    @oauth_proxy ||= Warden::Github::Oauth::Proxy.new(env['warden'].config[:github_client_id],
                                                      env['warden'].config[:github_secret],
                                                      env['warden'].config[:github_scopes],
                                                      env['warden'].config[:github_oauth_domain],
                                                      callback_url)
  end

  def user_info_for(token)
    @user_info ||= RestClient.get("https://api.github.com/user", :params => {:access_token => token})
  end

  def callback_url
    absolute_url(request, env['warden'].config[:github_callback_url], env['HTTP_X_FORWARDED_PROTO'])
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
end
