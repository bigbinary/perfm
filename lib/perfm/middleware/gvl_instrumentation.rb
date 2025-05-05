# frozen_string_literal: true

require "gvl_timing"

module Perfm
  module Middleware
    class GvlInstrumentation
      def initialize(app)
        @app = app
        @puma_max_threads = nil
      end
  
      def call(env)
        response = nil
        before_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        before_gc_time = GC.total_time
        
        timer = GVLTiming.measure do
          response = @app.call(env)
        end
        
        total_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - before_time
        gc_time = GC.total_time - before_gc_time
      
        begin
          @puma_max_threads ||= get_puma_max_threads if defined?(::Puma)
          
          data = {
            gc_ms: (gc_time / 1_000_000.0).round(2),
            run_ms: (timer.cpu_duration * 1000.0).round(2),
            idle_ms: (timer.idle_duration * 1000.0).round(2),
            stall_ms: (timer.stalled_duration * 1000.0).round(2),
            io_percent: (timer.idle_duration / total_time * 100.0).round(1),
            method: env["REQUEST_METHOD"],
            controller: nil,
            action: nil,
            puma_max_threads: @puma_max_threads
          }
          
          if (controller = env["action_controller.instance"])
            data[:controller] = controller.controller_path
            data[:action] = controller.action_name
          end
      
          Perfm.agent.push_metrics(data)
        rescue => e
          puts "GVL metrics collection failed: #{e.message}"
        end
      
        response
      end

      private

      def get_puma_max_threads
        JSON.parse(Puma.stats)["max_threads"]
      end
    end
  end
end
