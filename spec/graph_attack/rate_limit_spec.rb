# frozen_string_literal: true

module Dummy
  CUSTOM_REDIS_CLIENT = Redis.new

  class QueryType < GraphQL::Schema::Object
    field :inexpensive_field, String, null: false

    field :expensive_field, String, null: false do
      extension(GraphAttack::RateLimit, threshold: 5, interval: 15)
    end

    field :expensive_field_2, String, null: false do
      extension(GraphAttack::RateLimit, threshold: 10, interval: 15)
    end

    field :field_with_custom_redis_client, String, null: false do
      extension(
        GraphAttack::RateLimit,
        threshold: 10,
        interval: 15,
        redis_client: CUSTOM_REDIS_CLIENT,
      )
    end

    def inexpensive_field
      'result'
    end

    def expensive_field
      'result'
    end

    def expensive_field_2
      'result'
    end

    def field_with_custom_redis_client
      'result'
    end
  end

  class Schema < GraphQL::Schema
    query QueryType
  end
end

RSpec.describe GraphAttack::RateLimit do
  let(:schema) { Dummy::Schema }
  let(:redis) { Redis.current }
  let(:context) { { ip: '99.99.99.99' } }

  # Cleanup after ratelimit gem
  before do
    redis.scan_each(match: 'ratelimit:*') { |key| redis.del(key) }
  end

  describe 'fields without rate limiting' do
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

  describe 'fields with rate limiting' do
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

    context 'when rate limit is exceeded' do
      before do
        4.times do
          schema.execute('{ expensiveField }', context: context)
        end
      end

      it 'returns an error' do
        result = schema.execute('{ expensiveField }', context: context)

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
          result = schema.execute('{ expensiveField }', context: context2)

          expect(result).not_to have_key('errors')
          expect(result['data']).to eq('expensiveField' => 'result')
        end
      end
    end
  end

  describe 'several fields with rate limiting' do
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

        expect(result['errors']).to eq([expected_error])
        expect(result['data']).to be_nil
      end
    end

    context 'when both rate limits are exceeded' do
      let(:query) { '{ expensiveField expensiveField2 }' }
      let(:expected_error) do
        {
          'locations' => [{ 'column' => 3, 'line' => 1 }],
          'message' => 'Query rate limit exceeded',
          'path' => ['expensiveField'],
        }
      end

      before do
        10.times do
          schema.execute(query, context: context)
        end
      end

      it 'returns an error on the first exceeded limit' do
        result = schema.execute(query, context: context)

        expect(result['errors']).to eq([expected_error])
        expect(result['data']).to be_nil
      end
    end
  end

  context 'with a custom redis client field' do
    let(:redis) { Dummy::CUSTOM_REDIS_CLIENT }

    describe 'fields with rate limiting' do
      it 'inserts rate limits in the custom redis client' do
        schema.execute('{ expensiveField }', context: context)

        key = 'ratelimit:99.99.99.99:graphql-query-expensiveField'
        expect(redis.scan_each(match: key).count).to eq(1)
      end
    end
  end
end
