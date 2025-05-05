module Perfm
  module Errors
    class LatencyExceededError < StandardError
      attr_reader :queue, :latency, :expected_latency

      def initialize(queue:, latency:, expected_latency:)
        @queue = queue
        @latency = latency 
        @expected_latency = expected_latency

        message = "Queue latency exceeded SLA: #{latency.round(2)}s " \
                 "(limit: #{expected_latency}s) for queue #{queue}"
        super(message)
      end
    end
  end
end
