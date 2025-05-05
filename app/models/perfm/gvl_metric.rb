module Perfm
  class GvlMetric < ApplicationRecord
    self.table_name = "perfm_gvl_metrics"

    scope :within_time_range, ->(start_time, end_time) { 
      where(created_at: start_time..end_time) 
    }

    def action_path
      return "rack middleware" if controller.blank?
      "#{controller}##{action}"
    end
  end
end
