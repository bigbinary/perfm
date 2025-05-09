require "rails/engine"
require "active_support/all"
require "anyway_config"

require "perfm/version"
require "perfm/engine"

module Perfm
  autoload :Configuration, "perfm/configuration"
  autoload :Client, "perfm/client"
  autoload :Queue, "perfm/queue"
  autoload :Agent, "perfm/agent"
  autoload :GvlMetricsAnalyzer, "perfm/gvl_metrics_analyzer"
  autoload :SidekiqGvlMetricsAnalyzer, "perfm/sidekiq_gvl_metrics_analyzer"
  
  module Storage
    autoload :Base, "perfm/storage/base"
    autoload :Api, "perfm/storage/api"
    autoload :Local, "perfm/storage/local"
  end

  module Middleware
    autoload :GvlInstrumentation, "perfm/middleware/gvl_instrumentation"
    autoload :SidekiqGvlInstrumentation, "perfm/middleware/sidekiq_gvl_instrumentation"
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def agent
      @agent
    end

    def setup!
      return unless configuration.enabled?

      setup_sidekiq if configuration.monitor_sidekiq?
      setup_sidekiq_gvl if configuration.monitor_gvl?
      
      storage = if configuration.storage == :local
        Storage::Local.new
      else
        Storage::Api.new(Client.new(configuration))
      end
      
      @agent = Agent.new(configuration, storage)
    end

    def generate_heap_dump
      HeapDumper.generate
    end

    private

    def setup_sidekiq
      return unless defined?(::Sidekiq)
      Metrics::Sidekiq.setup
    end

    def setup_sidekiq_gvl
      return unless defined?(::Sidekiq)
      
      Sidekiq.configure_server do |config|
        config.server_middleware do |chain|
          chain.add Middleware::SidekiqGvlInstrumentation
        end
      end
    end
  end
end

require "perfm/engine" if defined?(Rails)
