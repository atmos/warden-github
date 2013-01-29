require 'spec_helper'

describe Warden::GitHub::User do
  let(:user) do
    Warden::GitHub::User.new({'login' => 'atmos'}, 'abcde')
  end

  it "knows the token" do
    user.token.should eql('abcde')
  end

  it "can access the octokit object to make api calls" do
    user.api.should_not be_nil
  end
end
