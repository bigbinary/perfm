module Perfm
  class Agent
    attr_reader :config, :queue

    def initialize(config, storage)
      @config = config
      @queue = Queue.new(storage)
    end

    def push_metrics(data)
      queue.push_metrics(data)
    end
  end
end
