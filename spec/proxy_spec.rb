require File.dirname(__FILE__) + '/spec_helper'

describe "Warden::Github::Oauth::Proxy" do
  before(:all) do
    sha = Digest::SHA1.hexdigest(Time.now.to_s)
    @proxy =  Warden::Github::Oauth::Proxy.new(sha[0..19], sha[0..39],
                                               'user,public_repo,repo,gist',
                                               'http://example.org',
                                               'http://example.org/auth/github/callback')
  end

  it "returns an authorize url" do
    uri = Addressable::URI.parse(@proxy.authorize_url)

    uri.scheme.should eql('http')
    uri.host.should eql('example.org')

    params = uri.query_values
    params['response_type'].should eql('code')
    params['scope'].should eql('user,public_repo,repo,gist')
    params['client_id'].should match(/\w{20}/)
    params['redirect_uri'].should eql('http://example.org/auth/github/callback')
  end

  it "has a client object" do
    @proxy.client.should_not be_nil
  end

  it "returns access tokens" do
    pending "this hits the network" do
      lambda { @proxy.access_token_for(/\w{20}/.gen) }.should_not raise_error
    end
  end
end
