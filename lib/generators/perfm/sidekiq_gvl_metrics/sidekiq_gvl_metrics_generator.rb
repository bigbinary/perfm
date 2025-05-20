require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record'

module Perfm
  class SidekiqGvlMetricsGenerator < Rails::Generators::Base
    include ActiveRecord::Generators::Migration
    source_root File.expand_path("templates", __dir__)
    
    def create_migration_file
      migration_template(
        'create_perfm_sidekiq_gvl_metrics.rb.erb',
        File.join(db_migrate_path, "create_perfm_sidekiq_gvl_metrics.rb")
      )
    end
    
    private
    
    def migration_version
      "[#{ActiveRecord::VERSION::STRING.to_f}]"
    end
  end
end 
