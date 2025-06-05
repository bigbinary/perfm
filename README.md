# Perfm

Perfm aims to be a performance monitoring tool for Ruby on Rails applications. Currently, it has support for GVL instrumentation and provides analytics to help optimize Puma thread concurrency settings based on the collected GVL data.

## Requirements

- Ruby: MRI 3.2+

This is because the GVL instrumentation API was [added](https://bugs.ruby-lang.org/issues/18339) in 3.2.0. Perfm makes use of the [gvl_timing](https://github.com/jhawthorn/gvl_timing) gem to capture per-thread timings for each GVL state.

## Installation

Add perfm to your Gemfile.

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

We just need around `20000` datapoints(i.e requests) to get an idea of the app's workload. So the `monitor_gvl` config can be disabled after that. You can control the value via an ENV variable if you prefer.

## Analysis

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

This will print the following metrics:

- `total_io_percentage`: Percentage of time spent doing I/O operations
- `total_io_and_stall_percentage`: Percentage of time spent in I/O operations(idle time) and GVL stalls combined
- `average_response_time_ms`: Average response time in milliseconds per request
- `average_stall_ms`: Average GVL stall time in milliseconds per request
- `average_gc_ms`: Average garbage collection time in milliseconds per request
- `request_count`: Total number of requests analyzed
- `time_range`: Details about the analysis period including:
  - `start_time`
  - `end_time`
  - `duration_seconds`

After analysis, you can drop the table to save space. The following command generates a migration to drop the table.

```bash
bin/rails generate perfm:uninstall
```

## Beta Features

The following features are currently in beta and may have limited functionality or be subject to change.

### Perfm queue latency monitor

The queue latency monitor tracks Sidekiq queue times and raises alerts when the queue latency exceed their thresholds. To enable this feature, set `config.monitor_sidekiq_queues = true` in your Perfm configuration.

ruby

```ruby
Perfm.configure do |config|
  # Other configurations...
  config.monitor_sidekiq_queues = true
end
```

When enabled, Perfm will monitor your Sidekiq queues and raise a `Perfm::Errors::LatencyExceededError` when the queue latency exceeds the threshold.

#### Queue Naming Convention

Perfm expects queues that need latency monitoring to follow this naming pattern:

- `within_X_seconds` (e.g., within_5_seconds)
- `within_X_minutes` (e.g., within_2_minutes)
- `within_X_hours` (e.g., within_1_hours)

### Sidekiq GVL Instrumentation

To enable GVL instrumentation for Sidekiq, first run the generator to add migrations for the required table to store the metrics.

```bash
bin/rails generate perfm:sidekiq_gvl_metrics
```

Then enable the `monitor_sidekiq_gvl` configuration in your initializer.

```ruby
Perfm.configure do |config|
  config.monitor_sidekiq_gvl = true
end
```

When enabled, Perfm will collect GVL metrics at a job level, similar to how it collects metrics for HTTP requests. This can be used to analyze GVL metrics specifically for Sidekiq queues to understand their I/O characteristics.

```ruby
Perfm::SidekiqGvlMetric.calculate_queue_io_percentage("within_5_seconds")
```

### Heap analyzer

### Generate and Store Heap Dumps via ActiveStorage

Perfm has a heap dump generator which can be used to generate heap dumps from running Puma worker processes and storing them via ActiveStorage. This can be useful for debugging memory leaks. We can generate three dumps separate by a time period of lets say 15 minutes and analyze it via heapy or sheap.

_Note: The process of heap dump generation can increase the memory usage._

#### Puma configuration changes:

Add the following to your `config/puma.rb`:

```ruby
on_worker_boot do
  Perfm::PidStore.instance.add_worker_pid(Process.pid)
end

on_worker_shutdown do
  Perfm::PidStore.instance.clear
end
```

We need to keep track of pid of each worker process so that we inject code to generate heap dump in each worker process using [rbtrace](https://github.com/tmm1/rbtrace)

#### Route setup

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :perfm do
    namespace :admin do
      resources :heap_dumps, only: :create
    end
  end
end
```

#### Controller to generate heap dumps

As we need to invoke rbtrace from the same process, we'll use a controller itself to invoke the `HeapDumper`.

```ruby
class Perfm::Admin::HeapDumpsController < ActionController::Base
  skip_forgery_protection
  before_action :authenticate_admin

  def create
    blob = Perfm::HeapDumper.generate

    render json: {
      status: "success",
      message: "Heap dump generated successfully",
      blob_id: blob.id,
      filename: blob.filename.to_s
    }
  rescue Perfm::HeapDumper::Error => e
    render json: { status: "error", message: e.message }, status: :unprocessable_entity
  end

  private

  def authenticate_admin
    return if Rails.env.development?

    unless valid_token?(request.headers["X-Perfm-Token"])
      head :unauthorized
    end
  end

  def valid_token?(token)
    return false if token.blank? || Perfm.configuration.admin_token.blank?

    ActiveSupport::SecurityUtils.secure_compare(
      token,
      Perfm.configuration.admin_token
    )
  end
end
```

#### Usage

```bash
curl -X POST https://your-app.com/perfm/admin/heap_dumps -H "X-Perfm-Token: your-secure-token"
```

The generated heap dump will be stored via ActiveStorage and the response includes the blob ID and filename for later reference.

#### Configuration

Configure the admin token in your Perfm initializer:

```ruby
# config/initializers/perfm.rb
Perfm.configure do |config|
  config.admin_token = ENV["PERFM_ADMIN_TOKEN"]
end
```

The generated heap dumps can be downloaded and analyzed using [heapy](https://github.com/zombocom/heapy)

We're planning to add a heap analyzer within perfm itself to make the process seamless.
