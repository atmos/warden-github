require File.dirname(__FILE__) + '/spec_helper'

describe "Warden::Github" do
  it "requesting an url that requires authentication redirects to github" do
    response = get "/"

    uri = Addressable::URI.parse(response.headers["Location"])

    uri.scheme.should eql('https')
    uri.host.should eql('github.com')

    params = uri.query_values
    params['response_type'].should eql('code')
    params['scope'].should eql('')
    params['client_id'].should match(/\w{20}/)
    params['redirect_uri'].should eql('http://example.org/auth/github/callback')
  end
end
