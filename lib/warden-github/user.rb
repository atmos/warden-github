module Warden
  module Github
    module Oauth
      class User < Struct.new(:attribs, :token)
        def name
          attribs['name']
        end

        def email
          attribs['email']
        end

        def company
          attribs['company']
        end
      end
    end
  end
end
