unreleased
----------

v2.2.0
------

Feature:
- Skip throttling when rate limited field is nil (#19)

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
