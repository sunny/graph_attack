# frozen_string_literal: true

module GraphAttack
  # Store the config
  class Configuration
    # Number of calls allowed.
    attr_accessor :threshold

    # Time interval in seconds.
    attr_accessor :interval

    # Key on the context on which to differentiate users.
    attr_accessor :on

    # Use a custom Redis client.
    attr_accessor :redis_client

    def initialize
      @threshold = nil
      @interval = nil
      @on = :ip
      @redis_client = Redis.new
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
