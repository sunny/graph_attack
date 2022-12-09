unreleased
----------

v2.2.0
------

Feature:
- Add context key exist validator
- Skip call to `calls_exceeded_on_query` when `rate_limited_field` is nil

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
