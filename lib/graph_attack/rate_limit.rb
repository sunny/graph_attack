# frozen_string_literal: true

module GraphAttack
  class RateLimit < GraphQL::Schema::FieldExtension
    def resolve(object:, arguments:, **_rest)
      rate_limited_field = object.context[on]

      unless object.context.key?(on)
        raise GraphAttack::Error, "Missing :#{on} key on the GraphQL context"
      end

      if rate_limited_field && calls_exceeded_on_query?(rate_limited_field)
        return RateLimited.new('Query rate limit exceeded')
      end

      yield(object, arguments)
    end

    private

    def key
      suffix = "-#{on}" if on != :ip

      "graphql-query-#{field.name}#{suffix}"
    end

    def calls_exceeded_on_query?(rate_limited_field)
      rate_limit = Ratelimit.new(rate_limited_field, redis: redis_client)
      rate_limit.add(key)

      rate_limit.exceeded?(key, threshold: threshold, interval: interval)
    end

    def threshold
      options[:threshold] ||
        GraphAttack.configuration.threshold ||
        raise(
          GraphAttack::Error,
          'Missing "threshold:" option on the GraphAttack::RateLimit extension',
        )
    end

    def interval
      options[:interval] ||
        GraphAttack.configuration.interval ||
        raise(
          GraphAttack::Error,
          'Missing "interval:" option on the GraphAttack::RateLimit extension',
        )
    end

    def redis_client
      options[:redis_client] || GraphAttack.configuration.redis_client
    end

    def on
      options[:on] || GraphAttack.configuration.on
    end
  end
end
