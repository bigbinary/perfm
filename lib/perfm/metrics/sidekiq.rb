module Perfm
  module Metrics
    class Sidekiq
      ERROR_RATE_LIMIT_SECONDS = 30

      class << self
        @last_error_times = {}
        @error_time_mutex = Mutex.new

        def setup
          start_monitoring
        end

        def start_monitoring
          Thread.new do
            while true
              collect_metrics
              sleep 5
            end
          end
        end

        def collect_metrics
          return unless defined?(::Sidekiq)

          ::Sidekiq::Queue.all.each do |queue|
            if monitor_sidekiq_queues? && valid_queue_name?(queue.name)
              check_latency_threshold(queue)
            end
          end
        end

        def check_latency_threshold(queue)
          return unless expected_latency = QueueLatency.parse_latency(queue.name)
          
          if queue.latency > expected_latency
            handle_exceeded_latency(queue, expected_latency)
          end
        end

        def handle_exceeded_latency(queue, expected_latency)
          return unless should_raise_error_for_queue?(queue.name)
          update_last_error_time(queue.name)

          Thread.new do
            raise Errors::LatencyExceededError.new(
              queue: queue.name,
              latency: queue.latency,
              expected_latency: expected_latency
            )
          end
        end

        def monitor_sidekiq_queues?
          @monitor_sidekiq_queues ||= Perfm.configuration.monitor_sidekiq_queues?
        end
  
        def valid_queue_name?(queue_name)
          QueueLatency.valid_queue_name?(queue_name)
        end

        private

        def should_raise_error_for_queue?(queue_name)
          @error_time_mutex.synchronize do
            last_error_time = @last_error_times[queue_name]
            return true unless last_error_time

            Time.current - last_error_time >= ERROR_RATE_LIMIT_SECONDS
          end
        end

        def update_last_error_time(queue_name)
          @error_time_mutex.synchronize do
            @last_error_times[queue_name] = Time.current
          end
        end
      end
    end
  end
end
