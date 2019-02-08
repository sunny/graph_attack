module GraphAttack
  # Query analyser you can add to your GraphQL schema to limit calls by IP.
  #
  #     ApplicationSchema = GraphQL::Schema.define do
  #       query_analyzer GraphAttack::RateLimiter.new
  #     end
  #
  class RateLimiter
    class Error < StandardError; end
    class RateLimited < GraphQL::AnalysisError; end

    def initial_value(query)
      {
        ip: query.context[:ip],
        query_rate_limits: [],
        redis_client: query.context[:redis_client]
      }
    end

    def call(memo, visit_type, irep_node)
      if rate_limited_node?(visit_type, irep_node)
        data = rate_limit_data(irep_node)

        memo[:query_rate_limits].push(data)

        increment_rate_limit(memo[:ip], data[:key], memo[:redis_client])
      end

      memo
    end

    def final_value(memo)
      handle_exceeded_calls_on_queries(memo)
    end

    private

    def increment_rate_limit(ip, key, redis_client)
      raise Error, 'Missing :ip value on the GraphQL context' unless ip

      rate_limit(ip, redis_client).add(key)
    end

    def rate_limit_data(node)
      data = node.definition.metadata[:rate_limit]

      data.merge(
        key: "graphql-query-#{node.name}",
        query_name: node.name,
      )
    end

    def handle_exceeded_calls_on_queries(memo)
      rate_limited_queries = memo[:query_rate_limits].map do |limit_data|
        next unless calls_exceeded_on_query?(memo[:ip], limit_data, memo[:redis_client])

        limit_data[:query_name]
      end.compact

      return unless rate_limited_queries.any?

      queries = rate_limited_queries.join(', ')
      RateLimited.new("Query rate limit exceeded on #{queries}")
    end

    def calls_exceeded_on_query?(ip, query_limit_data, redis_client)
      rate_limit(ip, redis_client).exceeded?(
        query_limit_data[:key],
        threshold: query_limit_data[:threshold],
        interval: query_limit_data[:interval],
      )
    end

    def rate_limit(ip, redis_client = Redis.new)
      @rate_limit ||= {}
      @rate_limit[ip] ||= Ratelimit.new(ip, redis: redis_client)
    end

    def rate_limited_node?(visit_type, node)
      query_field_node?(node) &&
        visit_type == :enter &&
        node.definition.metadata[:rate_limit]
    end

    def query_field_node?(node)
      node.owner_type.name == 'Query' &&
        node.ast_node.is_a?(GraphQL::Language::Nodes::Field)
    end
  end
end
