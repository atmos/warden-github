module Warden
  class SessionSerializer
    attr_reader :env

    def initialize(env)
      @env = env
    end

    def serialize(user)
      cookie_verifier.generate(user)
    end

    def deserialize(key)
      cookie_verifier.verify(key)
    rescue ::ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    private
    def verifier_key
      self.class.verifier_key
    end

    def self.verifier_key
      @verifier_key ||= ENV['WARDEN_GITHUB_VERIFIER_SECRET'] || SecureRandom.hex
    end

    def cookie_verifier
      @cookie_verifier ||= ::ActiveSupport::MessageVerifier.new(verifier_key, serializer: Marshal)
    end
  end
end
