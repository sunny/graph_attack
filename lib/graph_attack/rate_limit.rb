# frozen_string_literal: true

module GraphAttack
  class RateLimit < GraphQL::Schema::FieldExtension
    def resolve(object:, arguments:, **_rest)
      rate_limited_field = object.context[rate_limited_key]

      unless object.context.key?(rate_limited_key)
        raise GraphAttack::Error,
              "Missing :#{rate_limited_key} key on the GraphQL context"
      end

      if rate_limited_field && calls_exceeded_on_query?(rate_limited_field)
        return RateLimited.new('Query rate limit exceeded')
      end

      yield(object, arguments)
    end

    private

    def key
      on = "-#{options[:on]}" if options[:on]

      "graphql-query-#{field.name}#{on}"
    end

    def calls_exceeded_on_query?(rate_limited_field)
      rate_limit = Ratelimit.new(rate_limited_field, redis: redis_client)
      rate_limit.add(key)

      rate_limit.exceeded?(key, threshold: threshold, interval: interval)
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
      options[:redis_client] || Redis.new
    end

    def rate_limited_key
      options[:on] || :ip
    end
  end
end
