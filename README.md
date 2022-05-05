# GraphAttack

[![CircleCI](https://circleci.com/gh/sunny/graph_attack.svg?style=svg)](https://circleci.com/gh/sunny/graph_attack)

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

This would allow only 15 calls per minute by the same IP address.

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

## Configuration

Use a custom Redis client instead of the default:

```rb
  field :some_expensive_field, String, null: false do
    extension GraphAttack::RateLimit,
              threshold: 15,
              interval: 60,
              redis_client: Redis.new(url: "…")
  end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake` to run the tests and the linter. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

## Versionning

We use [SemVer](http://semver.org/) for versioning. For the versions available,
see the tags on this repository.

## Releasing

To release a new version, update the version number in `version.rb`, commit,
and then run `bin/rake release`, which will create a git tag for the version,
push git commits and tags, and push the gem to
[rubygems.org](https://rubygems.org).

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

- **Fanny Cheung** - [KissKissBankBank](https://github.com/KissKissBankBank)
- **Sunny Ripert** - [KissKissBankBank](https://github.com/KissKissBankBank)

## Acknowledgments

Hat tip to [Rack::Attack](https://github.com/kickstarter/rack-attack) for the
the name.
