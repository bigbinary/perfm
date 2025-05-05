module Perfm
  module QueueLatency
    QUEUE_PATTERN = /\Awithin_(\d+)_(second|seconds|minute|minutes|hour|hours)\z/i

    def self.parse_latency(queue_name)
      return unless valid_queue_name?(queue_name)

      match_data = queue_name.match(QUEUE_PATTERN)
      value = match_data[1].to_i
      unit = match_data[2].downcase.sub(/s\z/, '')

      case unit
      when 'second' then value
      when 'minute' then value * 60
      when 'hour' then value * 3600
      end
    end

    def self.valid_queue_name?(queue_name)
      queue_name&.match?(QUEUE_PATTERN)
    end
  end
end
