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
  end

  Schema = GraphQL::Schema.define do
    query QueryType
    query_analyzer GraphAttack::RateLimiter.new
  end
end

RSpec.describe GraphAttack::RateLimiter do
  # Cleanup
  before do
    redis = Redis.current
    redis.scan_each(match: 'ratelimit:*') { |key| redis.del(key) }
  end

  describe 'on fields without rate limiting' do
    it 'returns data' do
      result = Dummy::Schema.execute('{ inexpensiveField }')
      expect(result).not_to have_key('errors')
      expect(result['data']).to eq('inexpensiveField' => 'result')
    end
  end

  describe 'on fields with rate limiting' do
    subject { Dummy::Schema.execute('{ expensiveField }') }

    it 'returns data until rate limit is exceeded' do
      4.times do
        result = Dummy::Schema.execute('{ expensiveField }')
        expect(result).not_to have_key('errors')
        expect(result['data']).to eq('expensiveField' => 'result')
      end
    end

    it 'returns an error after the rate limit is exceeded' do
      result = nil

      5.times do
        result = Dummy::Schema.execute('{ expensiveField }')
      end

      expect(result['errors'])
        .to eq([{ 'message' => 'Query rate limit exceeded on expensiveField' }])
      expect(result).not_to have_key('data')
    end
  end
end
