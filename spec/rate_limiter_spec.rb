module Dummy
  QueryType = GraphQL::ObjectType.define do
    name 'Query'

    field :inexpensiveField do
      type types.String
      resolve ->(_obj, _args, _ctx) { 'result' }
    end

    field :expensiveField do
      rate_limit threshold: 5, interval: 15

      type types.String
      resolve ->(_obj, _args, _ctx) { 'result' }
    end

    field :expensiveField2 do
      rate_limit threshold: 10, interval: 15

      type types.String
      resolve ->(_obj, _args, _ctx) { 'result' }
    end
  end

  Schema = GraphQL::Schema.define do
    query QueryType
    query_analyzer GraphAttack::RateLimiter.new
  end

  CUSTOM_REDIS_CLIENT = Redis.new

  SchemaWithCustomRedisClient = GraphQL::Schema.define do
    query QueryType
    query_analyzer GraphAttack::RateLimiter.new(
      redis_client: CUSTOM_REDIS_CLIENT,
    )
  end
end

RSpec.describe GraphAttack::RateLimiter do
  let(:schema) { Dummy::Schema }
  let(:redis) { Redis.current }
  let(:context) { { ip: '99.99.99.99' } }

  # Cleanup after ratelimit gem
  before do
    redis.scan_each(match: 'ratelimit:*') { |key| redis.del(key) }
  end

  describe 'on fields without rate limiting' do
    it 'returns data' do
      result = schema.execute('{ inexpensiveField }', context: context)

      expect(result).not_to have_key('errors')
      expect(result['data']).to eq('inexpensiveField' => 'result')
    end

    it 'does not insert rate limits in redis' do
      schema.execute('{ inexpensiveField }', context: context)

      expect(redis.scan_each(match: 'ratelimit:*').count).to eq(0)
    end
  end

  describe 'on fields with rate limiting' do
    it 'inserts rate limits in redis' do
      schema.execute('{ expensiveField }', context: context)

      key = 'ratelimit:99.99.99.99:graphql-query-expensiveField'
      expect(redis.scan_each(match: key).count).to eq(1)
    end

    it 'returns data until rate limit is exceeded' do
      4.times do
        result = schema.execute('{ expensiveField }', context: context)

        expect(result).not_to have_key('errors')
        expect(result['data']).to eq('expensiveField' => 'result')
      end
    end

    context 'after rate limit is exceeded' do
      before do
        4.times do
          schema.execute('{ expensiveField }', context: context)
        end
      end

      it 'returns an error' do
        result = schema.execute('{ expensiveField }', context: context)

        expected_message = 'Query rate limit exceeded on expensiveField'
        expect(result['errors']).to eq([{ 'message' => expected_message }])
        expect(result).not_to have_key('data')
      end

      context 'on a different IP' do
        let(:context2) { { ip: '203.0.113.43' } }

        it 'does not return an error' do
          result = schema.execute('{ expensiveField }', context: context2)

          expect(result).not_to have_key('errors')
          expect(result['data']).to eq('expensiveField' => 'result')
        end
      end
    end
  end

  describe 'on several fields with rate limiting' do
    context 'after one rate limit is exceeded' do
      before do
        5.times do
          schema.execute(
            '{ expensiveField expensiveField2 }',
            context: context,
          )
        end
      end

      it 'returns an error message with only the first field' do
        result = schema.execute(
          '{ expensiveField expensiveField2 }',
          context: context,
        )

        expected_message = 'Query rate limit exceeded on expensiveField'
        expect(result['errors']).to eq([{ 'message' => expected_message }])
        expect(result).not_to have_key('data')
      end
    end

    context 'after both rate limits are exceeded' do
      before do
        10.times do
          schema.execute(
            '{ expensiveField expensiveField2 }',
            context: context,
          )
        end
      end

      it 'returns an error message with both fields' do
        result = schema.execute(
          '{ expensiveField expensiveField2 }',
          context: context,
        )

        expected_message =
          'Query rate limit exceeded on expensiveField, expensiveField2'
        expect(result['errors']).to eq([{ 'message' => expected_message }])
        expect(result).not_to have_key('data')
      end
    end
  end

  context 'with custom redis client' do
    let(:schema) { Dummy::SchemaWithCustomRedisClient }
    let(:redis) { Dummy::CUSTOM_REDIS_CLIENT }

    describe 'on fields with rate limiting' do
      it 'inserts rate limits in the custom redis client' do
        schema.execute('{ expensiveField }', context: context)

        key = 'ratelimit:99.99.99.99:graphql-query-expensiveField'
        expect(redis.scan_each(match: key).count).to eq(1)
      end
    end
  end
end
