module Perfm
  module Storage
    class Local < Base
      def store(metrics)
        return if metrics.empty?

        Perfm::GvlMetric.insert_all(metrics)
      end
    end
  end
end
