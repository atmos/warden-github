warden-github
=============

A [warden](http://github.com/hassox/warden) strategy that provides oauth authentication to github.  Find out more about enabling your application at github's [oauth quickstart](http://gist.github.com/419219).

To test it out on localhost set your callback url to 'http://localhost:9292/auth/github/callback'

There's an example app in [example/app.rb](/atmos/warden-github/blob/master/example/app.rb).

Using with GitHub Enterprise
============================

Export the `OCTOKIT_API_ENDPOINT` environmental variable to the URL of your enterprise install.

The Extension in Action
=======================
    % gem install bundler
    % bundle install
    % GITHUB_CLIENT_ID="<from GH>" GITHUB_CLIENT_SECRET="<from GH>" bundle exec rackup -p9393 -E none
