# frozen_string_literal: true

module Dummy
  CUSTOM_REDIS_CLIENT = Redis.new
  POOLED_REDIS_CLIENT = ConnectionPool.new(size: 5, timeout: 5) do
    Redis.new
  end

  class QueryType < GraphQL::Schema::Object
    field :inexpensive_field, String, null: false

    field :expensive_field, String, null: false do
      extension GraphAttack::RateLimit, threshold: 5, interval: 15
    end

    field :expensive_field2, String, null: false do
      extension GraphAttack::RateLimit, threshold: 10, interval: 15
    end

    field :field_with_custom_redis_client, String, null: false do
      extension GraphAttack::RateLimit,
                threshold: 10,
                interval: 15,
                redis_client: CUSTOM_REDIS_CLIENT
    end

    field :field_with_pooled_redis_client, String, null: false do
      extension GraphAttack::RateLimit,
                threshold: 10,
                interval: 15,
                redis_client: POOLED_REDIS_CLIENT
    end

    field :field_with_on_option, String, null: false do
      extension GraphAttack::RateLimit,
                threshold: 10,
                interval: 15,
                on: :client_id
    end

    field :field_with_defaults, String, null: false do
      extension GraphAttack::RateLimit
    end

    def inexpensive_field
      'result'
    end

    def expensive_field
      'result'
    end

    def expensive_field2
      'result'
    end

    def field_with_custom_redis_client
      'result'
    end

    def field_with_pooled_redis_client
      'result'
    end

    def field_with_on_option
      'result'
    end

    def field_with_defaults
      'result'
    end
  end

  class Schema < GraphQL::Schema
    query QueryType
  end
end

RSpec.describe GraphAttack::RateLimit do
  let(:schema) { Dummy::Schema }
  let(:redis) { Redis.new }
  let(:context) { { ip: '99.99.99.99' } }

  before do
    # Clean up after ratelimit gem.
    redis.then do |client|
      client.scan_each(match: 'ratelimit:*') { |key| client.del(key) }
    end

    # Clean up configuration changes.
    GraphAttack.configuration = GraphAttack::Configuration.new
  end

  context 'when context has IP key' do
    describe 'fields without rate limiting' do
      let(:query) { '{ inexpensiveField }' }

      it 'returns data' do
        result = schema.execute(query, context: context)

        expect(result).not_to have_key('errors')
        expect(result['data']).to eq('inexpensiveField' => 'result')
      end

      it 'does not insert rate limits in redis' do
        schema.execute(query, context: context)

        expect(redis.scan_each(match: 'ratelimit:*').count).to eq(0)
      end
    end

    describe 'fields with rate limiting' do
      let(:query) { '{ expensiveField }' }

      it 'inserts rate limits in redis' do
        schema.execute(query, context: context)

        key = 'ratelimit:99.99.99.99:graphql-query-expensiveField'
        expect(redis.scan_each(match: key).count).to eq(1)
      end

      it 'returns data until rate limit is exceeded' do
        4.times do
          result = schema.execute(query, context: context)

          expect(result).not_to have_key('errors')
          expect(result['data']).to eq('expensiveField' => 'result')
        end
      end

      context 'when rate limit is exceeded' do
        before do
          4.times do
            schema.execute(query, context: context)
          end
        end

        it 'returns an error' do
          result = schema.execute(query, context: context)

          expected_error = {
            'locations' => [{ 'column' => 3, 'line' => 1 }],
            'message' => 'Query rate limit exceeded',
            'path' => ['expensiveField'],
          }
          expect(result['errors']).to eq([expected_error])
          expect(result['data']).to be_nil
        end

        context 'when on a different IP' do
          let(:context2) { { ip: '203.0.113.43' } }

          it 'does not return an error' do
            result = schema.execute(query, context: context2)

            expect(result).not_to have_key('errors')
            expect(result['data']).to eq('expensiveField' => 'result')
          end
        end
      end
    end

    describe 'fields with defaults' do
      let(:query) { '{ fieldWithDefaults }' }

      context 'with no defaults' do
        it 'raises' do
          expect do
            schema.execute(query, context: context)
          end.to raise_error(GraphAttack::Error, /Missing "threshold:" option/)
        end
      end

      context 'with defaults' do
        let(:new_redis) { Redis.new }
        let(:context) { { client_token: 'abc89' } }

        before do
          GraphAttack.configure do |c|
            c.threshold = 3
            c.interval = 30
            c.on = :client_token
            c.redis_client = new_redis
          end
        end

        after do
          new_redis.scan_each(match: 'ratelimit:*') { |key| new_redis.del(key) }
        end

        it 'inserts rate limits using the defaults' do
          schema.execute(query, context: context)

          key = 'ratelimit:abc89:graphql-query-fieldWithDefaults-client_token'
          expect(new_redis.scan_each(match: key).count).to eq(1)
        end

        it 'returns an error when the default rate limit is exceeded' do
          2.times do
            result = schema.execute(query, context: context)

            expect(result).not_to have_key('errors')
            expect(result['data']).to eq('fieldWithDefaults' => 'result')
          end

          result = schema.execute(query, context: context)

          expected_error = {
            'locations' => [{ 'column' => 3, 'line' => 1 }],
            'message' => 'Query rate limit exceeded',
            'path' => ['fieldWithDefaults'],
          }
          expect(result['errors']).to eq([expected_error])
          expect(result['data']).to be_nil
        end
      end
    end

    describe 'several fields with rate limiting' do
      let(:query) { '{ expensiveField expensiveField2 }' }

      context 'when one rate limit is exceeded' do
        let(:expected_error) do
          {
            'locations' => [{ 'column' => 3, 'line' => 1 }],
            'message' => 'Query rate limit exceeded',
            'path' => ['expensiveField'],
          }
        end

        before do
          5.times do
            schema.execute(query, context: context)
          end
        end

        it 'returns an error message with only the first field' do
          result = schema.execute(query, context: context)

          expect(result['errors']).to eq([expected_error])
          expect(result['data']).to be_nil
        end
      end

      context 'when both rate limits are exceeded' do
        let(:expected_errors) do
          [
            {
              'locations' => [{ 'column' => 3, 'line' => 1 }],
              'message' => 'Query rate limit exceeded',
              'path' => ['expensiveField'],
            },
            {
              'locations' => [{ 'column' => 18, 'line' => 1 }],
              'message' => 'Query rate limit exceeded',
              'path' => ['expensiveField2'],
            },
          ]
        end

        before do
          10.times do
            schema.execute(query, context: context)
          end
        end

        it 'returns an error on both' do
          result = schema.execute(query, context: context)

          expect(result['errors']).to eq(expected_errors)
          expect(result['data']).to be_nil
        end
      end
    end

    context 'with a custom redis client field' do
      let(:redis) { Dummy::CUSTOM_REDIS_CLIENT }
      let(:query) { '{ fieldWithCustomRedisClient }' }

      it 'inserts rate limits in the custom redis client' do
        schema.execute(query, context: context)

        key = 'ratelimit:99.99.99.99:graphql-query-fieldWithCustomRedisClient'
        expect(redis.scan_each(match: key).count).to eq(1)
      end
    end

    context 'with a pooled redis client field' do
      let(:redis) { Dummy::POOLED_REDIS_CLIENT }
      let(:query) { '{ fieldWithPooledRedisClient }' }

      it 'inserts rate limits in the custom redis client' do
        schema.execute(query, context: context)

        key = 'ratelimit:99.99.99.99:graphql-query-fieldWithPooledRedisClient'
        expect(redis.then { _1.scan_each(match: key).count }).to eq(1)
      end
    end

    describe 'fields with the on option' do
      let(:query) { '{ fieldWithOnOption }' }
      let(:context) { { client_id: '0cca3dfc-6638' } }

      it 'inserts rate limits in redis' do
        schema.execute(query, context: context)

        key = 'ratelimit:0cca3dfc-6638:graphql-query-fieldWithOnOption-' \
              'client_id'
        expect(redis.scan_each(match: key).count).to eq(1)
      end

      it 'returns data until rate limit is exceeded' do
        9.times do
          result = schema.execute(query, context: context)

          expect(result).not_to have_key('errors')
          expect(result['data']).to eq('fieldWithOnOption' => 'result')
        end
      end

      context 'when rate limit is exceeded' do
        before do
          9.times do
            schema.execute(query, context: context)
          end
        end

        it 'returns an error' do
          result = schema.execute(query, context: context)

          expected_error = {
            'locations' => [{ 'column' => 3, 'line' => 1 }],
            'message' => 'Query rate limit exceeded',
            'path' => ['fieldWithOnOption'],
          }
          expect(result['errors']).to eq([expected_error])
          expect(result['data']).to be_nil
        end

        context 'when on a different :on value' do
          let(:context2) do
            { client_id: '25be1c42-0cf1-424e-acfe-d8d31939a1c0' }
          end

          it 'does not return an error' do
            result = schema.execute(query, context: context2)

            expect(result).not_to have_key('errors')
            expect(result['data']).to eq('fieldWithOnOption' => 'result')
          end
        end
      end
    end
  end

  context 'when context has not IP key' do
    let(:query) { '{ expensiveField }' }

    it 'returns an error' do
      expect { schema.execute(query) }.to raise_error(
        GraphAttack::Error, /Missing :ip key on the GraphQL context/
      )
    end
  end
end
