module Perfm
  class GvlMetricsAnalyzer
    class Error < StandardError; end

    def initialize(start_time:, end_time:, puma_max_threads: nil)
      @start_time = start_time
      @end_time = end_time
      @puma_max_threads = puma_max_threads
    end

    def analyze
      return empty_results if metrics.empty?
      
      {
        summary: calculate_summary(metrics),
        percentiles: calculate_percentiles(metrics),
        action_breakdowns: calculate_action_breakdowns(metrics)
      }
    end

    private

      def metrics
        @_metrics ||= begin
          base_scope = GvlMetric.within_time_range(@start_time, @end_time)
          return base_scope unless @puma_max_threads

          base_scope.where(puma_max_threads: @puma_max_threads)
        end
      end


      def empty_results
        {
          total_io_percentage: 0.0,
          total_stall_percentage: 0.0,
          average_response_time_ms: 0.0,
          average_stall_ms: 0.0,
          average_gc_ms: 0.0,
          request_count: 0,
          time_range: {
            start_time: @start_time,
            end_time: @end_time,
            duration_seconds: (@end_time - @start_time).to_i
          }
        }
      end

      def calculate_io_percentage(run_ms, idle_ms)
        total_time = run_ms + idle_ms
        return 0.0 if total_time == 0
        ((idle_ms / total_time) * 100.0).round(2)
      end

      def calculate_avg_response_time(run_ms, idle_ms, stall_ms, count)
        return 0.0 if count == 0
        ((stall_ms + run_ms + idle_ms) / count).round(2)
      end

      def calculate_summary(metrics)
        total_run_ms = metrics.sum(:run_ms)
        total_idle_ms = metrics.sum(:idle_ms)
        total_stall_ms = metrics.sum(:stall_ms)
        total_gc_ms = metrics.sum(:gc_ms)
        count = metrics.count
        
        {
          total_io_percentage: calculate_io_percentage(total_run_ms, total_idle_ms),
          average_response_time_ms: calculate_avg_response_time(total_run_ms, total_idle_ms, total_stall_ms, count),
          average_stall_ms: (total_stall_ms / count).round(2),
          average_gc_ms: (total_gc_ms / count).round(2),
          request_count: count,
          time_range: {
            start_time: @start_time,
            end_time: @end_time,
            duration_seconds: (@end_time - @start_time).to_i
          }
        }
      end

      def calculate_percentiles(metrics)
        total_count = metrics.size

        sorted_metrics = if metrics.is_a?(ActiveRecord::Relation)
          metrics.order(Arel.sql("run_ms + idle_ms + stall_ms")).to_a
        else
          metrics.sort_by { |m| m.run_ms + m.idle_ms + m.stall_ms }
        end
        
        p10 = (total_count * 0.1).floor
        p50 = (total_count * 0.5).floor
        p60 = (total_count * 0.6).floor
        p90 = (total_count * 0.9).floor
        p99 = (total_count * 0.99).floor
        p999 = (total_count * 0.999).floor

        percentile_ranges = {
          "p0-10": 0...p10,
          "p50-60": p50...p60,
          "p90-99": p90...p99,
          "p99-99.9": p99...p999,
          "p99.9-100": p999...total_count
        }

        result = {
          overall: "#{total_count} requests"
        }
        
        result.merge!(
          percentile_ranges.transform_values do |range|
            range_metrics = sorted_metrics[range]
            calculate_group_stats_in_memory(range_metrics || [])
          end
        )

        result
      end

      def calculate_action_breakdowns(metrics)
        metrics_by_action = metrics.group_by do |metric|
          [metric.controller, metric.action]
        end
      
        metrics_by_action.transform_keys do |(controller, action)|
          "#{controller}##{action}"
        end.transform_values do |action_metrics|
          calculate_percentiles(action_metrics)
        end
      end

      def calculate_group_stats_in_memory(metrics)
        return empty_group_stats if metrics.empty?

        avg_run_ms = (metrics.sum(&:run_ms) / metrics.size).round(1)
        avg_idle_ms = (metrics.sum(&:idle_ms) / metrics.size).round(1)
        avg_stall_ms = (metrics.sum(&:stall_ms) / metrics.size).round(1)
        avg_gc_ms = (metrics.sum(&:gc_ms) / metrics.size).round(1)
        total_ms = (avg_run_ms + avg_idle_ms + avg_stall_ms).round(1)
        
        io_percentage = if (avg_run_ms + avg_idle_ms) > 0
          ((avg_idle_ms / (avg_run_ms + avg_idle_ms)) * 100).round(1)
        else
          0.0
        end

        {
          cpu: avg_run_ms,
          io: avg_idle_ms,
          stall: avg_stall_ms,
          gc: avg_gc_ms,
          total: total_ms,
          "io%": "#{io_percentage}%",
          count: metrics.size
        }
      end

      def empty_group_stats
        {
          cpu: 0.0,
          io: 0.0,
          stall: 0.0,
          gc: 0.0,
          total: 0.0,
          "io%": "0.0%",
          count: 0
        }
      end
  end
end
