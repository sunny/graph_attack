# frozen_string_literal: true

RSpec.describe GraphAttack::Configuration do
  let(:configuration) { GraphAttack.configuration }

  describe '.configuration' do
    it 'assigns defaults' do
      expect(configuration).to be_a(described_class)
      expect(configuration.threshold).to be_nil
      expect(configuration.interval).to be_nil
      expect(configuration.on).to eq(:ip)
      expect(configuration.redis_client).to be_a(Redis)
    end
  end

  describe '.configure' do
    let(:redis) { instance_double Redis }

    after do
      GraphAttack.configuration = described_class.new
    end

    it 'can set new values' do
      GraphAttack.configure do |c|
        c.threshold = 99
        c.interval = 30
        c.on = :client_token
        c.redis_client = redis
      end

      expect(configuration.threshold).to eq(99)
      expect(configuration.interval).to eq(30)
      expect(configuration.on).to eq(:client_token)
      expect(configuration.redis_client).to eq(redis)
    end
  end
end
