module Perfm
  module Storage
    class Local < Base
      def store(metrics)
        return if metrics.empty?

        if metrics.first.key?(:job_class)
          SidekiqGvlMetric.insert_all(metrics)
        else
          Perfm::GvlMetric.insert_all(metrics)
        end
      end
    end
  end
end
