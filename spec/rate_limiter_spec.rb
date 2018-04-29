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
end

RSpec.describe GraphAttack::RateLimiter do
  # Cleanup after ratelimit gem
  before do
    redis = Redis.current
    redis.scan_each(match: 'ratelimit:*') { |key| redis.del(key) }
  end

  let(:context) { { ip: '203.0.113.42' } }
  let(:context2) { { ip: '203.0.113.43' } }

  describe 'on fields without rate limiting' do
    it 'returns data' do
      result = Dummy::Schema.execute('{ inexpensiveField }', context: context)

      expect(result).not_to have_key('errors')
      expect(result['data']).to eq('inexpensiveField' => 'result')
    end
  end

  describe 'on fields with rate limiting' do
    it 'returns data until rate limit is exceeded' do
      4.times do
        result = Dummy::Schema.execute('{ expensiveField }', context: context)

        expect(result).not_to have_key('errors')
        expect(result['data']).to eq('expensiveField' => 'result')
      end
    end

    context 'after rate limit is exceeded' do
      before do
        4.times do
          Dummy::Schema.execute('{ expensiveField }', context: context)
        end
      end

      it 'returns an error' do
        result = Dummy::Schema.execute('{ expensiveField }', context: context)

        expected_message = 'Query rate limit exceeded on expensiveField'
        expect(result['errors']).to eq([{ 'message' => expected_message }])
        expect(result).not_to have_key('data')
      end

      it 'does not return an error for a different IP' do
        result = Dummy::Schema.execute('{ expensiveField }', context: context2)

        expect(result).not_to have_key('errors')
        expect(result['data']).to eq('expensiveField' => 'result')
      end
    end
  end

  describe 'on several fields with rate limiting' do
    context 'after one rate limit is exceeded' do
      before do
        5.times do
          Dummy::Schema.execute(
            '{ expensiveField expensiveField2 }',
            context: context,
          )
        end
      end

      it 'returns an error message with only the first field' do
        result = Dummy::Schema.execute(
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
          Dummy::Schema.execute(
            '{ expensiveField expensiveField2 }',
            context: context,
          )
        end
      end

      it 'returns an error message with both fields' do
        result = Dummy::Schema.execute(
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
end
