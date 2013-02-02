require 'spec_helper'

describe Warden::GitHub do
  it "requesting an url that requires authentication redirects to github" do
    response = get "/profile"

    uri = Addressable::URI.parse(response.headers["Location"])

    uri.scheme.should eql('https')
    uri.host.should eql('github.com')

    params = uri.query_values
    params['client_id'].should match(/\w{20}/)
    params['redirect_uri'].should eql('http://example.org/profile')
  end
end
