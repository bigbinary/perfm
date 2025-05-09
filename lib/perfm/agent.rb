module Perfm
  class Agent
    attr_reader :config, :queue, :sidekiq_queue

    def initialize(config, storage)
      @config = config
      @queue = Queue.new(storage)
      @sidekiq_queue = Queue.new(storage)
    end

    def push_metrics(data)
      queue.push_metrics(data)
    end

    def push_sidekiq_metrics(data)
      sidekiq_queue.push_metrics(data)
    end
  end
end
