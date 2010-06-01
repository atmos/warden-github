module Warden
  module Github
    module Oauth
      class User < Struct.new(:attribs, :token)
        extend Forwardable

        def name
          attribs['name']
        end

        def email
          attribs['email']
        end
      end
    end
  end
end
