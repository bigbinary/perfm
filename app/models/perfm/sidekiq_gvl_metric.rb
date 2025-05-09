module Perfm
  class SidekiqGvlMetric < ApplicationRecord
    self.table_name = "perfm_sidekiq_gvl_metrics"
  end

  scope :within_time_range, ->(start_time, end_time) { 
    where(created_at: start_time..end_time) 
  }
end
