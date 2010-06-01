require File.dirname(__FILE__) + '/spec_helper'

describe "Warden::Github" do
  it "requesting an url that requires authentication redirects to github" do
    response = get "/"

    uri = Addressable::URI.parse(response.headers["Location"])
    uri.should_not be_nil
    uri.scheme.should eql('https')

    params = uri.query_values
    params['type'].should eql('web_server')
    params['scope'].should eql('email,offline_access')
    params['client_id'].should match(/\w{20}/)
    params['redirect_uri'].should eql('http://example.org/auth/github/callback')
  end
end
