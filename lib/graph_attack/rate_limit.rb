# frozen_string_literal: true

module GraphAttack
  class RateLimit < GraphQL::Schema::FieldExtension
    def resolve(object:, arguments:, **_rest)
      ip = object.context[:ip]
      raise GraphAttack::Error, 'Missing :ip value on the GraphQL context' unless ip

      return RateLimited.new('Query rate limit exceeded') if calls_exceeded_on_query?(ip)

      yield(object, arguments)
    end

    private

    def key
      "graphql-query-#{field.name}"
    end

    def calls_exceeded_on_query?(ip)
      rate_limit = Ratelimit.new(ip, redis: redis_client)
      rate_limit.add(key)
      rate_limit.exceeded?(
        key,
        threshold: threshold,
        interval: interval,
      )
    end

    def threshold
      options[:threshold] ||
        raise(
          GraphAttack::Error,
          'Missing "threshold:" option on the GraphAttack::RateLimit extension',
        )
    end

    def interval
      options[:interval] ||
        raise(
          GraphAttack::Error,
          'Missing "interval:" option on the GraphAttack::RateLimit extension',
        )
    end

    def redis_client
      options[:redis_client] || Redis.current
    end
  end
end
