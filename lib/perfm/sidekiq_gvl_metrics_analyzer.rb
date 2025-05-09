require "json"

module Perfm
  class SidekiqGvlMetricsAnalyzer
    attr_reader :start_time, :end_time, :query

    def initialize(start_time: nil, end_time: nil, job_class: nil, queue: nil)
      @start_time = start_time
      @end_time = end_time
      @query = SidekiqGvlMetric.where(true)
      @query = @query.where(job_class: job_class) if job_class
      @query = @query.where(queue: queue) if queue
      @query = @query.where(created_at: start_time..end_time) if start_time && end_time
    end

    def analyze
      return {} if query.count.zero?

      result = {}
      result[:total_io_percentage] = total_io_percentage
      result[:total_io_and_stall_percentage] = total_io_and_stall_percentage
      result[:average_processing_time_ms] = average_processing_time_ms
      result[:average_stall_ms] = average_stall_ms
      result[:job_count] = job_count
      result[:time_range] = time_range_info
      result[:by_job_class] = metrics_by_job_class
      result[:by_queue] = metrics_by_queue
      result
    end

    private

    def average_io_ms
      query.average(:idle_ms).to_f
    end

    def average_stall_ms
      query.average(:stall_ms).to_f
    end

    def average_run_ms
      query.average(:run_ms).to_f
    end

    def average_processing_time_ms
      average_run_ms + average_io_ms + average_stall_ms
    end

    def job_count
      query.count
    end

    def total_io_percentage
      (average_io_ms / average_processing_time_ms * 100).round(1)
    end

    def total_io_and_stall_percentage
      ((average_io_ms + average_stall_ms) / average_processing_time_ms * 100).round(1)
    end

    def time_range_info
      range_start = start_time || query.minimum(:created_at)
      range_end = end_time || query.maximum(:created_at)
      duration = range_end - range_start

      {
        start_time: range_start.iso8601,
        end_time: range_end.iso8601,
        duration_seconds: duration.to_i
      }
    end

    def metrics_by_job_class
      results = {}
      
      job_classes = query.distinct.pluck(:job_class)
      job_classes.each do |job_class|
        job_query = query.where(job_class: job_class)
        
        job_avg_processing_ms = job_query.average(:run_ms).to_f + 
                              job_query.average(:idle_ms).to_f + 
                              job_query.average(:stall_ms).to_f
        
        job_avg_io_ms = job_query.average(:idle_ms).to_f
        job_avg_stall_ms = job_query.average(:stall_ms).to_f
        
        results[job_class] = {
          count: job_query.count,
          average_processing_time_ms: job_avg_processing_ms.round(1),
          average_io_ms: job_avg_io_ms.round(1),
          average_stall_ms: job_avg_stall_ms.round(1),
          io_percentage: (job_avg_io_ms / job_avg_processing_ms * 100).round(1),
          io_and_stall_percentage: ((job_avg_io_ms + job_avg_stall_ms) / job_avg_processing_ms * 100).round(1)
        }
      end
      
      results
    end
    
    def metrics_by_queue
      results = {}
      
      queues = query.distinct.pluck(:queue)
      queues.each do |queue|
        queue_query = query.where(queue: queue)
        
        queue_avg_processing_ms = queue_query.average(:run_ms).to_f + 
                                queue_query.average(:idle_ms).to_f + 
                                queue_query.average(:stall_ms).to_f
        
        queue_avg_io_ms = queue_query.average(:idle_ms).to_f
        queue_avg_stall_ms = queue_query.average(:stall_ms).to_f
        
        results[queue] = {
          count: queue_query.count,
          average_processing_time_ms: queue_avg_processing_ms.round(1),
          average_io_ms: queue_avg_io_ms.round(1),
          average_stall_ms: queue_avg_stall_ms.round(1),
          io_percentage: (queue_avg_io_ms / queue_avg_processing_ms * 100).round(1),
          io_and_stall_percentage: ((queue_avg_io_ms + queue_avg_stall_ms) / queue_avg_processing_ms * 100).round(1)
        }
      end
      
      results
    end
  end
end 
