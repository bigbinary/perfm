module Perfm
  class Configuration < Anyway::Config
    config_name :perfm
    
    attr_config(
      enabled: true,
      monitor_sidekiq: false,
      monitor_gvl: false,
      monitor_sidekiq_queues: false,
      storage: :api,
      api_url: nil,
      api_key: nil,
    )

    def monitor_sidekiq?
      enabled? && monitor_sidekiq
    end

    def monitor_gvl?
      enabled? && monitor_gvl
    end

    def enabled?
      enabled
    end
  end
end
