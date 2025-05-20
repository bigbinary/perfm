module Perfm
  class Engine < ::Rails::Engine
    isolate_namespace Perfm
    
    initializer "perfm.gvl_instrumentation" do |app|
      if Perfm.configuration.monitor_gvl?
        app.config.middleware.insert(0, Perfm::Middleware::GvlInstrumentation)
      end
      
      if Perfm.configuration.monitor_sidekiq_gvl? && defined?(Sidekiq)
        Sidekiq.configure_server do |config|
          config.server_middleware do |chain|
            chain.add Perfm::Middleware::SidekiqGvlInstrumentation
          end
        end
      end
    end
  end
end
