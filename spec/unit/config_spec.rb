require 'spec_helper'

describe Warden::GitHub::Config do
  let(:warden_scope) { :test_scope }

  let(:env) do
    { 'warden' => double(config: warden_config) }
  end

  let(:warden_config) do
    { scope_defaults: { warden_scope => { config: scope_config } } }
  end

  let(:scope_config) do
    {}
  end

  let(:request) do
    double(url: 'http://example.com/the/path', path: '/the/path')
  end

  subject(:config) do
    described_class.new(env, warden_scope)
  end

  before do
    allow(config).to receive_messages(request: request)
  end

  def silence_warnings
    old_verbose, $VERBOSE = $VERBOSE, nil
    yield
  ensure
    $VERBOSE = old_verbose
  end

  describe '#client_id' do
    context 'when specified in scope config' do
      it 'returns the client id' do
        scope_config[:client_id] = 'foobar'
        expect(config.client_id).to eq 'foobar'
      end
    end

    context 'when specified in deprecated config' do
      it 'returns the client id' do
        warden_config[:github_client_id] = 'foobar'
        silence_warnings do
          expect(config.client_id).to eq 'foobar'
        end
      end
    end

    context 'when specified in ENV' do
      it 'returns the client id' do
        allow(ENV).to receive(:[]).with('GITHUB_CLIENT_ID').and_return('foobar')
        expect(config.client_id).to eq 'foobar'
      end
    end

    context 'when not specified' do
      it 'raises BadConfig' do
        expect { config.client_id }.to raise_error(described_class::BadConfig)
      end
    end
  end

  describe '#client_secret' do
    context 'when specified in scope config' do
      it 'returns the client secret' do
        scope_config[:client_secret] = 'foobar'
        expect(config.client_secret).to eq 'foobar'
      end
    end

    context 'when specified in deprecated config' do
      it 'returns the client secret' do
        warden_config[:github_secret] = 'foobar'
        silence_warnings do
          expect(config.client_secret).to eq 'foobar'
        end
      end
    end

    context 'when specified in ENV' do
      it 'returns the client secret' do
        allow(ENV).to receive(:[]).with('GITHUB_CLIENT_SECRET').and_return('foobar')
        silence_warnings do
          expect(config.client_secret).to eq 'foobar'
        end
      end
    end

    context 'when not specified' do
      it 'raises BadConfig' do
        expect { config.client_secret }.to raise_error(described_class::BadConfig)
      end
    end
  end

  describe '#redirect_uri' do
    context 'when specified in scope config' do
      it 'returns the expanded redirect uri' do
        scope_config[:redirect_uri] = '/callback'
        expect(config.redirect_uri).to eq 'http://example.com/callback'
      end
    end

    context 'when specified path lacks leading slash' do
      it 'corrects the path and returns the expanded uri' do
        scope_config[:redirect_uri] = 'callback'
        expect(config.redirect_uri).to eq 'http://example.com/callback'
      end
    end

    context 'when specified in deprecated config' do
      it 'returns the expanded redirect uri' do
        warden_config[:github_callback_url] = '/callback'
        silence_warnings do
          expect(config.redirect_uri).to eq 'http://example.com/callback'
        end
      end
    end

    context 'when not specified' do
      it 'returns the expanded redirect uri with the current path' do
        expect(config.redirect_uri).to eq 'http://example.com/the/path'
      end
    end

    context 'when HTTP_X_FORWARDED_PROTO is set to https' do
      it 'returns the expanded redirect uri(with port) with adjusted scheme' do
        env['HTTP_X_FORWARDED_PROTO'] = 'https'
        allow(request).to receive_messages(url: 'http://example.com:443/the/path')
        expect(config.redirect_uri).to eq 'https://example.com/the/path'
      end

      it 'returns the expanded redirect uri with adjusted scheme including port 80' do
        env['HTTP_X_FORWARDED_PROTO'] = 'https'
        allow(request).to receive_messages(url: 'http://example.com:80/the/path')
        expect(config.redirect_uri).to eq 'https://example.com/the/path'
      end

      it 'returns the expanded redirect uri with adjusted scheme including port 80 with multiple forwarded protocols' do
        env['HTTP_X_FORWARDED_PROTO'] = 'https,https'
        allow(request).to receive_messages(url: 'https://example.com:80/the/path')
        expect(config.redirect_uri).to eq 'https://example.com/the/path'
      end

      it 'returns the expanded redirect uri(without port) with adjusted scheme' do
        env['HTTP_X_FORWARDED_PROTO'] = 'https'
        allow(request).to receive_messages(url: 'http://example.com/the/path')
        expect(config.redirect_uri).to eq 'https://example.com/the/path'
      end
    end
  end

  describe '#scope' do
    context 'when specified in scope config' do
      it 'returns the client secret' do
        scope_config[:scope] = 'user'
        expect(config.scope).to eq 'user'
      end
    end

    context 'when specified in deprecated config' do
      it 'returns the client secret' do
        warden_config[:github_scopes] = 'user'
        silence_warnings do
          expect(config.scope).to eq 'user'
        end
      end
    end

    context 'when not specified' do
      it 'returns nil' do
        expect(config.scope).to be_nil
      end
    end
  end

  describe '#to_hash' do
    it 'includes all configs' do
      scope_config.merge!(
        scope:         'user',
        client_id:     'abc',
        client_secret: '123',
        redirect_uri:  '/foo')

      expect(config.to_hash.keys).
        to match_array([:scope, :client_id, :client_secret, :redirect_uri])
    end
  end
end
