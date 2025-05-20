module Perfm
  class SidekiqGvlMetric < ApplicationRecord
    self.table_name = "perfm_sidekiq_gvl_metrics"

    scope :within_time_range, ->(start_time, end_time) { 
      where(created_at: start_time..end_time) 
    }

    def self.calculate_queue_io_percentage(queue_name, start_time: nil, end_time: nil)
      scope = where(queue: queue_name)
      scope = scope.within_time_range(start_time, end_time) if start_time && end_time

      total_run_ms = scope.sum(:run_ms)
      total_idle_ms = scope.sum(:idle_ms)
      
      total_time = total_run_ms + total_idle_ms
      return 0.0 if total_time == 0
      
      ((total_idle_ms.to_f / total_time) * 100.0).round(2)
    end
  end
end
