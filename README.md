# warden-github

A [warden](https://github.com/hassox/warden) strategy that provides oauth authentication to github.  Find out more about enabling your application at github's [oauth quickstart](http://gist.github.com/419219).

## The Extension in Action

To play with the extension, follow these steps:

1.  [Create an application on GitHub](https://github.com/settings/applications/new) and set the callback URL to `http://localhost:9292`
2.  Run the following command with the client id and client secret obtained from the previous step:

        % GITHUB_CLIENT_ID="<from GH>" GITHUB_CLIENT_SECRET="<from GH>" bundle exec rackup

    This will run the example app [example/simple_app.rb](example/simple_app.rb).

    If you wish to see multiple user scopes in action, run the above command with an additional variable:

        % MULTI_SCOPE_APP=1 GITHUB_CLIENT_ID="<from GH>" GITHUB_CLIENT_SECRET="<from GH>" bundle exec rackup

    This will run the example app [example/multi_scope_app.rb](example/multi_scope_app.rb).

3.  Point your browser at [http://localhost:9292/](http://localhost:9292) and enjoy!

## Configuration

In order to use this strategy, simply tell warden about it.
This is done by using `Warden::Manager` as a rack middleware and passing a config block to it.
Read more about warden setup at the [warden wiki](https://github.com/hassox/warden/wiki/Setup).

For simple usage without customization, simply specify it as the default strategy.

```ruby
use Warden::Manager do |config|
  config.failure_app = BadAuthentication
  config.default_strategies :github
end
```

In order to pass custom configurations, you need to configure a warden scope.
Note that the default warden scope (i.e. when not specifying any explicit scope) is `:default`.

Here's an example that specifies configs for the default scope and a custom admin scope.

```ruby
use Warden::Manager do |config|
  config.failure_app = BadAuthentication
  config.default_strategies :github

  config.scope_defaults :default, :config => { :scope => 'user:email' }
  config.scope_defaults :admin, :config => { :client_id     => 'foobar',
                                             :client_secret => 'barfoo',
                                             :scope         => 'user,repo',
                                             :redirect_uri  => '/admin/oauth/callback' }
end
```

### Multiple Scopes Usage

Using multiple scopes allows you to have different user types:

```ruby
env['warden'].authenticate                  # => Uses the configs from the default scope.
env['warden'].authenticate :scope => :admin # => Uses the configs from the admin scope.

env['warden'].user         # => The user for the default scope.
env['warden'].user(:admin) # => The user for the admin scope.

env['warden'].logout           # => Logs out all scopes.
env['warden'].logout(:default) # => Logs out the default scope.
env['warden'].logout(:admin)   # => Logs out the default scope.
```

### Parameters

The config parameters and their defaults are listed below.
Please refer to the [GitHub OAuth documentation](http://developer.github.com/v3/oauth/) for an explanation of their meaning.

- **client_id:** Defaults to `ENV['GITHUB_CLIENT_ID']` and raises if not present.
- **client_secret:** Defaults to `ENV['GITHUB_CLIENT_SECRET']` and raises if not present.
- **scope:** Defaults to `nil`.
- **redirect_uri:** Defaults to the current path.
  Note that paths will be expanded to a valid URL using the request url's host.

## Using with GitHub Enterprise

Export the `OCTOKIT_API_ENDPOINT` environmental variable to the URL of your enterprise install.
