warden-github
=============

A [warden](http://github.com/hassox/warden) strategy that provides oauth authentication to github.  Find out more about enabling your application at github's [oauth quickstart](http://gist.github.com/419219).

To test it out on localhost set your callback url to 'http://localhost:9292/auth/github/callback'

There's an example app in [spec/app.rb](/atmos/warden-github/blob/master/spec/app.rb).

The Extension in Action
=======================
    % gem install bundler
    % bundle install
    % GITHUB_CLIENT_ID="<from GH>" GITHUB_CLIENT_SECRET="<from GH>" bundle exec rackup -p9393 -E none
