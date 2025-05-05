require "singleton"

# TODO: Or read from Puma pidfile?
# TODO: Handle single mode

module Perfm
  class PidStore
    include Singleton
    
    def initialize
      @worker_pids = Concurrent::Array.new
    end

    def add_worker_pid(pid)
      @worker_pids << pid
    end

    def get_first_worker_pid
      @worker_pids.sample
    end

    def clear
      @worker_pids.clear
    end
  end
end
