module Perfm
  class Queue
    FLUSH_INTERVAL = 60
    FLUSH_THRESHOLD = 100

    def initialize(storage)
      @metrics = []
      @storage = storage
      @mutex = Mutex.new
      Kernel.at_exit { flush }
      start_thread
    end

    def push_metrics(data)
      mutex.synchronize do
        @metrics.push(data)
        wakeup_thread if @metrics.size >= FLUSH_THRESHOLD || !thread.alive?
      end
    end

    def collect_pending_metrics
      result = nil
      mutex.synchronize do
        if @metrics.size > 0
          result = @metrics
          @metrics = []
        end
      end
      result
    end

    def flush
      if data = collect_pending_metrics
        @storage.store(data)
      end
    end

    def flush_indefinitely
      while true
        sleep(FLUSH_INTERVAL) and flush
      end
    end

    private

    attr_reader :mutex, :thread

    def start_thread
      @thread = Thread.new { flush_indefinitely }
    end

    def wakeup_thread
      (thread && thread.alive?) ? thread.wakeup : start_thread
    end
  end
end
