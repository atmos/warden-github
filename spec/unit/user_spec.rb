require 'spec_helper'

describe Warden::GitHub::User do
  let(:default_attrs) do
    { 'login' => 'john',
      'name' => 'John Doe',
      'gravatar_id' => '38581cb351a52002548f40f8066cfecg',
      'avatar_url' => 'http://example.com/avatar.jpg',
      'email' => 'john@doe.com',
      'company' => 'Doe, Inc.' }
  end
  let(:token) { 'the_token' }

  let(:user) do
    described_class.new(default_attrs, token)
  end

  let(:sso_user) do
    described_class.new(default_attrs, token, "abcdefghijklmnop")
  end

  describe '#token' do
    it 'returns the token' do
      expect(user.token).to eq token
    end
  end

  %w[login name gravatar_id avatar_url email company].each do |name|
    describe "##{name}" do
      it "returns the #{name}" do
        expect(user.send(name)).to eq default_attrs[name]
      end
    end
  end

  describe '#api' do
    it 'returns a preconfigured Octokit client for the user' do
      api = user.api

      expect(api).to be_an Octokit::Client
      expect(api.login).to eq user.login
      expect(api.access_token).to eq user.token
    end
  end

  def stub_api(user, method, args, ret)
    api = double
    allow(user).to receive_messages(api: api)
    expect(api).to receive(method).with(*args).and_return(ret)
  end

  [:organization_public_member?, :organization_member?].each do |method|
    describe "##{method}" do
      context 'when user is not member' do
        it 'returns false' do
          stub_api(user, method, ['rails', user.login], false)
          expect(user.send(method, 'rails')).to be_falsey
        end
      end

      context 'when user is member' do
        it 'returns true' do
          stub_api(user, method, ['rails', user.login], true)
          expect(user.send(method, 'rails')).to be_truthy
        end
      end
    end
  end

  describe '#team_member?' do
    context 'when user is not member' do
      it 'returns false' do
        api = double()
        allow(user).to receive_messages(api: api)

        allow(api).to receive(:team_member?).with(123, user.login).and_return(false)

        expect(user).not_to be_team_member(123)
      end
    end

    context 'when user is member' do
      it 'returns true' do
        api = double()
        allow(user).to receive_messages(api: api)
        allow(api).to receive(:team_member?).with(123, user.login).and_return(true)

        expect(user).to be_team_member(123)
      end
    end
  end

  describe '.load' do
    it 'loads the user data from GitHub and creates an instance' do
      client = double
      attrs = {}

      expect(Octokit::Client).
        to receive(:new).
        with(access_token: token).
        and_return(client)
      expect(client).to receive(:user).and_return(attrs)

      user = described_class.load(token)

      expect(user.attribs).to eq attrs
      expect(user.token).to eq token
    end
  end

  # NOTE: This always passes on MRI 1.9.3 because of ruby bug #7627.
  it 'marshals correctly' do
    expect(Marshal.load(Marshal.dump(user))).to eq user
  end

  describe 'single sign out' do
    it "knows if the user is using single sign out" do
      expect(user).not_to be_using_single_sign_out
      expect(sso_user).to be_using_single_sign_out
    end

    context "browser reverification" do
      it "handles success" do
        stub_user_session_request.to_return(status: 204, body: "", headers: {})
        expect(sso_user).to be_browser_session_valid
      end

      it "handles failure" do
        stub_user_session_request.to_return(status: 404, body: "", headers: {})
        expect(sso_user).not_to be_browser_session_valid
      end

      it "handles GitHub being unavailable" do
        stub_user_session_request.to_raise(Octokit::ServerError.new)
        expect(sso_user).to be_browser_session_valid
      end

      it "handles authentication failures" do
        stub_user_session_request.to_return(status: 403, body: "", headers: {})
        expect(sso_user).not_to be_browser_session_valid
      end
    end
  end
end
