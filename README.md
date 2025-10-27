# Perfm

Perfm aims to be a performance monitoring tool for Ruby on Rails applications. Currently, it has support for GVL instrumentation and provides analytics to help optimize Puma thread concurrency settings based on the collected GVL data.

## Requirements

- Ruby: MRI 3.2+

This is because the GVL instrumentation API was [added](https://bugs.ruby-lang.org/issues/18339) in 3.2.0. Perfm makes use of the [gvl_timing](https://github.com/jhawthorn/gvl_timing) gem to capture per-thread timings for each GVL state.

## Installation

Add perfm to the Gemfile.

```ruby
gem 'perfm'
```

To set up GVL instrumentation run the following command:

```bash
bin/rails generate perfm:install
```

This will create a migration file with a table to store the GVL metrics. Run the migration and configure the gem as described below.

## Configuration

Configure Perfm in an initializer:

```ruby
Perfm.configure do |config|
  config.enabled = true
  config.monitor_gvl = true
  config.storage = :local
end

Perfm.setup!

```

When `monitor_gvl` is enabled, perfm adds a Rack middleware to log GVL metrics for each request. The metrics are stored in the database.

We just need around `20000` datapoints(i.e requests) to get an idea of the app's workload. So the `monitor_gvl` config can be disabled after that. We can control the value via an ENV variable if we prefer.

## Analysis

Run the following in the Rails console to analyze the GVL metrics.

```ruby
gvl_metrics_analyzer = Perfm::GvlMetricsAnalyzer.new(
  start_time: 5.days.ago,
  end_time: Time.current
)

gvl_metrics_analyzer.analyze

# Write to file
File.write(
 "tmp/perfm/gvl_analysis_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json",
  JSON.pretty_generate(gvl_metrics_analyzer.analyze)
)
```

<details>
<summary>Example output</summary>

```json
{
  "summary": {
    "total_io_percentage": 56.34,
    "average_response_time_ms": 128.17,
    "average_stall_ms": 17.77,
    "average_gc_ms": 10.09,
    "request_count": 84,
    "time_range": {
      "start_time": "2025-10-22 12:33:36 UTC",
      "end_time": "2025-10-27 12:33:36 UTC",
      "duration_seconds": 432000
    }
  },
  "percentiles": {
    "overall": "84 requests",
    "p0-10": {
      "cpu": 0.5,
      "io": 0.1,
      "stall": 0.0,
      "gc": 0.0,
      "total": 0.6,
      "io%": "16.7%",
      "count": 8
    },
    "p50-60": {
      "cpu": 60.1,
      "io": 31.7,
      "stall": 2.8,
      "gc": 3.0,
      "total": 94.6,
      "io%": "34.5%",
      "count": 8
    },
    "p90-99": {
      "cpu": 128.3,
      "io": 279.7,
      "stall": 61.2,
      "gc": 22.3,
      "total": 469.2,
      "io%": "68.6%",
      "count": 8
    },
    "p99-99.9": {
      "cpu": 0.0,
      "io": 0.0,
      "stall": 0.0,
      "gc": 0.0,
      "total": 0.0,
      "io%": "0.0%",
      "count": 0
    },
    "p99.9-100": {
      "cpu": 166.5,
      "io": 747.4,
      "stall": 0.4,
      "gc": 7.9,
      "total": 914.3,
      "io%": "81.8%",
      "count": 1
    }
  },
  "action_breakdowns": {
    "#": {
      "overall": "43 requests",
      "p0-10": {
        "cpu": 0.5,
        "io": 0.1,
        "stall": 0.0,
        "gc": 0.0,
        "total": 0.6,
        "io%": "16.7%",
        "count": 4
      },
      "p50-60": {
        "cpu": 0.8,
        "io": 0.3,
        "stall": 0.1,
        "gc": 0.0,
        "total": 1.2,
        "io%": "27.3%",
        "count": 4
      },
      "p90-99": {
        "cpu": 2.0,
        "io": 14.4,
        "stall": 1.3,
        "gc": 1.1,
        "total": 17.7,
        "io%": "87.8%",
        "count": 4
      },
      "p99-99.9": {
        "cpu": 0.0,
        "io": 0.0,
        "stall": 0.0,
        "gc": 0.0,
        "total": 0.0,
        "io%": "0.0%",
        "count": 0
      },
      "p99.9-100": {
        "cpu": 56.6,
        "io": 21.8,
        "stall": 91.0,
        "gc": 68.4,
        "total": 169.4,
        "io%": "27.8%",
        "count": 1
      }
    },
    "api/v1/projects#show": {
      "overall": "4 requests",
      "p99.9-100": {
        "cpu": 229.1,
        "io": 101.5,
        "stall": 0.4,
        "gc": 26.2,
        "total": 331.0,
        "io%": "30.7%",
        "count": 1
      }
    },
    "api/v1/projects/runs#index": {
      "overall": "4 requests",
      "p99.9-100": {
        "cpu": 166.5,
        "io": 747.4,
        "stall": 0.4,
        "gc": 7.9,
        "total": 914.3,
        "io%": "81.8%",
        "count": 1
      }
    },
    "api/v1/projects/runs/test_entities#index": {
      "overall": "4 requests",
      "p99.9-100": {
        "cpu": 85.0,
        "io": 192.1,
        "stall": 0.4,
        "gc": 15.4,
        "total": 277.5,
        "io%": "69.3%",
        "count": 1
      }
    },
    "api/v1/projects/runs#show": {
      "overall": "3 requests",
      "p99.9-100": {
        "cpu": 104.6,
        "io": 158.8,
        "stall": 0.6,
        "gc": 2.1,
        "total": 264.0,
        "io%": "60.3%",
        "count": 1
      }
    },
    "api/v1/projects/runs/test_entities/result_histories#index": {
      "overall": "3 requests",
      "p99.9-100": {
        "cpu": 88.1,
        "io": 312.3,
        "stall": 79.2,
        "gc": 14.4,
        "total": 479.6,
        "io%": "78.0%",
        "count": 1
      }
    },
    "api/v1/projects/runs/test_entities/outcomes#index": {
      "overall": "3 requests",
      "p99.9-100": {
        "cpu": 119.7,
        "io": 234.8,
        "stall": 150.5,
        "gc": 16.1,
        "total": 505.0,
        "io%": "66.2%",
        "count": 1
      }
    },
    "api/v1/projects/runs/test_entities#show": {
      "overall": "3 requests",
      "p99.9-100": {
        "cpu": 123.4,
        "io": 257.9,
        "stall": 155.2,
        "gc": 15.9,
        "total": 536.5,
        "io%": "67.6%",
        "count": 1
      }
    }
  }
}
```

</details>

This will print the following metrics:

- `total_io_percentage`: Percentage of time spent doing I/O operations
- `total_io_and_stall_percentage`: Percentage of time spent in I/O operations (idle time) and GVL stalls combined. [See this blog for more details.](https://bigbinary.com/blog/tuning-puma-max-threads-configuration-with-gvl-instrumentation#:~:text=I/O%20operations.-,Stalled,-%3A%20The%20thread%20wants)
- `average_response_time_ms`: Average response time in milliseconds per request
- `average_stall_ms`: Average GVL stall time in milliseconds per request
- `average_gc_ms`: Average garbage collection time in milliseconds per request
- `request_count`: Total number of requests analyzed
- `time_range`: Details about the analysis period including:
  - `start_time`
  - `end_time`
  - `duration_seconds`

After analysis, we can drop the table to save space. The following command generates a migration to drop the table.

```bash
bin/rails generate perfm:uninstall
```

## Beta Features

The following features are currently in beta and may have limited functionality or be subject to change.

### Sidekiq queue latency monitor

The queue latency monitor tracks Sidekiq queue times and raises alerts when the queue latency exceed their thresholds. To enable this feature, set `config.monitor_sidekiq_queues = true` in the Perfm configuration.

```ruby
Perfm.configure do |config|
  # Other configurations...
  config.monitor_sidekiq_queues = true
end
```

When enabled, Perfm will monitor the Sidekiq queues and raise a `Perfm::Errors::LatencyExceededError` when the queue latency exceeds the threshold.

#### Queue Naming Convention

Perfm expects queues that need latency monitoring to be named in the following format. If the queue is not named in this format, it will not be considered.

- `within_X_seconds` (e.g., within_5_seconds)
- `within_X_minutes` (e.g., within_2_minutes)
- `within_X_hours` (e.g., within_1_hours)

### Sidekiq GVL Instrumentation

To enable GVL instrumentation for Sidekiq, first run the generator to add migrations for the required table to store the metrics.

```bash
bin/rails generate perfm:sidekiq_gvl_metrics
```

Then enable the `monitor_sidekiq_gvl` configuration.

```ruby
Perfm.configure do |config|
  config.monitor_sidekiq_gvl = true
end
```

When enabled, Perfm will collect GVL metrics at a job level, similar to how it collects metrics for HTTP requests. This can be used to analyze GVL metrics specifically for Sidekiq queues to understand their I/O characteristics.

```ruby
Perfm::SidekiqGvlMetric.calculate_queue_io_percentage("within_5_seconds")
```
