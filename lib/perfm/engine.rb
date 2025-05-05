module Perfm
  class Engine < ::Rails::Engine
    isolate_namespace Perfm
    
    initializer "perfm.gvl_instrumentation" do |app|
      if Perfm.configuration.monitor_gvl?
        app.config.middleware.insert(0, Perfm::Middleware::GvlInstrumentation)
      end
    end
  end
end
