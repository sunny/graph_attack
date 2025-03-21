unreleased
----------

Support:
- Drop Ruby 2.7 support.

v2.3.1
------

Fix:
- Relax Ruby version constraint to allow Ruby 3.2.

v2.3.0
------

Feature:
- Add configuration for setting defaults. E.g.:

    ```rb
    GraphAttack.configure do |config|
      # config.threshold = 15
      # config.interval = 60
      # config.on = :ip
      # config.redis_client = Redis.new
    end
    ```

v2.2.0
------

Feature:
- Skip throttling when rate limited field is nil (#19)

⚠️ Possibly breaking change:
- If your app relied on `Redis.current`, please provide a `redis_client` option
  explicitly, since
  [`Redis.current` is deprecated](https://github.com/redis/redis-rb/commit/9745e22db65ac294be51ed393b584c0f8b72ae98)
  and will be removed in Redis 5.

v2.1.0
------

Feature:
- Add support to custom rate limited context key with the `on:` option.

v2.0.0
------

Breaking changes:
- Drop support for GraphQL legacy schema, please use GraphQL::Ruby's class-based
  syntax exclusively.

Feature:
- Support Ruby 3.

v1.2.0
------

Feature:
- New GraphAttack::RateLimit extension to be used in GraphQL::Ruby's class-based
  syntax.

v1.1.0
------

Feature:
- Add `redis_client` option to provide a custom Redis client.

v1.0.0
------

First release!
