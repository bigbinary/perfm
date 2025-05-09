require "gvl_timing"

module Perfm
  module Middleware
    class SidekiqGvlInstrumentation
      def call(job_instance, job_payload, queue)
        before_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        before_gc_time = GC.total_time
        
        timer = GVLTiming.measure do
          yield
        end
        
        total_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - before_time
        gc_time = GC.total_time - before_gc_time
      
        begin
          data = {
            gc_ms: (gc_time / 1_000_000.0).round(2),
            run_ms: (timer.cpu_duration * 1000.0).round(2),
            idle_ms: (timer.idle_duration * 1000.0).round(2),
            stall_ms: (timer.stalled_duration * 1000.0).round(2),
            io_percent: (timer.idle_duration / total_time * 100.0).round(1),
            job_class: job_payload["class"],
            queue: queue
          }
      
          Perfm.agent.push_sidekiq_metrics(data)
        rescue => e
          puts "Sidekiq GVL metrics collection failed: #{e.message}"
        end
      end
    end
  end
end 
