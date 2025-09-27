# GraphAttack

[![Build Status](https://app.travis-ci.com/sunny/graph_attack.svg?branch=main)](https://app.travis-ci.com/sunny/graph_attack)

GraphQL analyser for blocking & throttling.

## Usage

This gem adds a method to limit access to your GraphQL fields by IP address:

```rb
class QueryType < GraphQL::Schema::Object
  field :some_expensive_field, String, null: false do
    extension GraphAttack::RateLimit, threshold: 15, interval: 60
  end

  # …
end
```

This would allow 15 requests per minute by the same IP address, blocking the 16th and subsequent requests within that 60-second window.

## Requirements

Requires [GraphQL Ruby](http://graphql-ruby.org/) and a running instance
of [Redis](https://redis.io/).

## Installation

Add these lines to your application’s `Gemfile`:

```ruby
# GraphQL analyser for blocking & throttling by IP.
gem "graph_attack"
```

And then execute:

```sh
$ bundle
```

Finally, make sure you add the current user’s IP address as `ip:` to the
GraphQL context. E.g.:

```rb
class GraphqlController < ApplicationController
  def create
    result = ApplicationSchema.execute(
      params[:query],
      variables: params[:variables],
      context: {
        ip: request.ip,
      },
    )
    render json: result
  end
end
```

If that key is `nil`, throttling will be disabled.

## Configuration

### Custom context key

If you want to throttle using a different value than the IP address, you can
choose which context key you want to use with the `on` option. E.g.:

```rb
extension GraphAttack::RateLimit,
          threshold: 15,
          interval: 60,
          on: :client_id
```

### Custom Redis client

Use a custom Redis client instead of the default with the `redis_client` option:

```rb
extension GraphAttack::RateLimit,
          threshold: 15,
          interval: 60,
          redis_client: Redis.new(url: "…")
```

### Common configuration

To have a default configuration for all rate-limited fields, you can create an
initializer:

```rb
GraphAttack.configure do |config|
  # config.threshold = 15
  # config.interval = 60
  # config.on = :ip
  # config.redis_client = Redis.new
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bin/rake` to run the tests and the linter. You can also run `bin/console` for
an interactive prompt that will allow you to experiment.

## Versionning

We use [SemVer](http://semver.org/) for versioning. For the versions available,
see the tags on this repository.

## Releasing

To release a new version, update the version number in `version.rb` and in the
`CHANGELOG.md`. Update the `README.md` if there are missing segments, make sure
tests and linting are pristine by calling `bundle && bin/rake`, then create a
commit for this version, for example with:

```sh
git add --patch
git commit -m v`ruby -rbundler/setup -rgraph_attack/version -e "puts GraphAttack::VERSION"`
```

You can then run `bin/rake release`, which will assign a git tag, push using
git, and push the gem to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/sunny/graph_attack. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the GraphAttack project’s codebases, issue trackers,
chat rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/sunny/graph_attack/blob/main/CODE_OF_CONDUCT.md).

## License

This project is licensed under the MIT License - see the
[LICENSE.md](https://github.com/sunny/graph_attack/blob/main/LICENSE.md)
file for details.

## Authors

- [Fanny Cheung](https://github.com/Ynote) — [ynote.hk](https://ynote.hk)
- [Sunny Ripert](https://github.com/sunny) — [sunfox.org](https://sunfox.org)

## Acknowledgments

Hat tip to [Rack::Attack](https://github.com/kickstarter/rack-attack) for the
the name.

Sponsored by [Cults](https://cults3d.com).

![Cults. Logo](https://github.com/user-attachments/assets/3a51b90d-1033-4df5-a903-03668fc4b966)
