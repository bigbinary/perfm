module Perfm
  module Storage
    class Api < Base
      def initialize(client)
        @client = client
      end

      def store(metrics)
        @client.post("/metrics", metrics: metrics)
      end
    end
  end
end
