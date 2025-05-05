module Perfm
  module Metrics
    class Sidekiq
      class << self
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
            record_queue_metrics(queue)
            
            if monitor_sidekiq_queues? && valid_queue_name?(queue.name)
              check_latency_threshold(queue)
            end
          end
        end

        def record_queue_metrics(queue)
          # TODO: Replace this with sending metrics to NewRelic as perfm-ingester work is not complete
          Perfm.agent.push_metrics({
            type: "sidekiq_queue",
            queue: queue.name,
            latency: queue.latency,
            size: queue.size,
          })
        end

        def check_latency_threshold(queue)
          return unless expected_latency = QueueLatency.parse_latency(queue.name)
          
          if queue.latency > expected_latency
            handle_exceeded_latency(queue, expected_latency)
          end
        end

        def handle_exceeded_latency(queue, expected_latency)
          Thread.new do
            # TODO: Prevent flooding the error monitoring tool if there are a lot of latency exceeded errors
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
      end
    end
  end
end
