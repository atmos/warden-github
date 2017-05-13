require 'spec_helper'

describe 'OAuth' do
  let(:code) { '1234' }

  def stub_code_for_token_exchange(answer='access_token=the_token')
    stub_request(:post, 'https://github.com/login/oauth/access_token').
      with(body: hash_including(code: code)).
      to_return(status: 200, body: answer)
  end

  def stub_user_retrieval
    stub_request(:get, 'https://api.github.com/user').
      with(headers: { 'Authorization' => 'token the_token' }).
      to_return(
        status: 200,
        body: File.read('spec/fixtures/user.json'),
        headers: { 'Content-Type' => 'application/json; charset=utf-8' })
  end

  def redirect_uri(response)
    Addressable::URI.parse(response.headers['Location'])
  end

  context 'when accessing a protected url' do
    it 'redirects to GitHub for authentication' do
      unauthenticated_response = get '/profile'
      github_uri = redirect_uri(unauthenticated_response)

      expect(github_uri.scheme).to eq 'https'
      expect(github_uri.host).to eq 'github.com'
      expect(github_uri.path).to eq '/login/oauth/authorize'
      expect(github_uri.query_values['client_id']).to match(/\w+/)
      expect(github_uri.query_values['state']).to match(/\w+/)
      expect(github_uri.query_values['redirect_uri']).to match(/^http.*\/profile$/)
    end
  end

  context 'when redirected back from GitHub' do
    it 'exchanges the code for an access token' do
      stub_code_for_token_exchange
      stub_user_retrieval

      unauthenticated_response = get '/login'
      github_uri = redirect_uri(unauthenticated_response)
      state = github_uri.query_values['state']

      get "/login?code=#{code}&state=#{state}"
    end

    context 'and the returned state does not match the initial state' do
      it 'fails authentication' do
        get '/login'
        response = get "/login?code=#{code}&state=foobar"

        expect(response).not_to be_successful
        expect(response.body).to include 'State mismatch'
      end
    end

    context 'and GitHub rejects the code while exchanging it for an access token' do
      it 'fails authentication' do
        stub_code_for_token_exchange('error=bad_verification_code')

        unauthenticated_response = get '/login'
        github_uri = redirect_uri(unauthenticated_response)
        state = github_uri.query_values['state']
        response = get "/login?code=#{code}&state=#{state}"

        expect(response).not_to be_successful
        expect(response.body).to include 'Bad verification code'
      end
    end

    context 'and the user denied access' do
      it 'fails authentication' do
        unauthenticated_response = get '/login'
        github_uri = redirect_uri(unauthenticated_response)
        state = github_uri.query_values['state']
        response = get "/login?error=access_denied&state=#{state}"

        expect(response).not_to be_successful
        expect(response.body).to include 'access denied'
      end
    end

    context 'and code was exchanged for an access token' do
      it 'redirects back to the original path' do
        stub_code_for_token_exchange
        stub_user_retrieval

        unauthenticated_response = get '/profile?foo=bar'
        github_uri = redirect_uri(unauthenticated_response)
        state = github_uri.query_values['state']

        callback_response = get "/profile?code=#{code}&state=#{state}"
        authenticated_uri = redirect_uri(callback_response)

        expect(authenticated_uri.path).to eq '/profile'
        expect(authenticated_uri.query).to eq 'foo=bar'
      end
    end

    context 'with GitHub SSO and code was exchanged for an access token' do
      it 'redirects back to the original path' do
        stub_code_for_token_exchange
        stub_user_retrieval

        unauthenticated_response = get '/profile?foo=bar'
        github_uri = redirect_uri(unauthenticated_response)
        state = github_uri.query_values['state']

        callback_response = get "/profile?code=#{code}&state=#{state}&browser_session_id=abcdefghijklmnop"
        authenticated_uri = redirect_uri(callback_response)

        expect(authenticated_uri.path).to eq '/profile'
        expect(authenticated_uri.query).to eq 'foo=bar'
      end
    end
  end

  context 'when not inside OAuth flow' do
    it 'does not recognize a seeming callback url as an actual callback' do
      response = get '/profile?state=foo&code=bar'

      expect(a_request(:post, 'https://github.com/login/oauth/access_token')).
        to have_not_been_made
    end
  end

  context 'when already authenticated' do
    it 'does not perform the OAuth flow again' do
      stub_code_for_token_exchange
      stub_user_retrieval

      unauthenticated_response = get '/login'
      github_uri = redirect_uri(unauthenticated_response)
      state = github_uri.query_values['state']

      callback_response = get "/login?code=#{code}&state=#{state}"
      authenticated_uri = redirect_uri(callback_response)
      get authenticated_uri.path
      logged_in_response = get '/login'

      expect(redirect_uri(logged_in_response).path).to eq '/'
    end
  end
end
