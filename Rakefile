begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rdoc/task'
require 'bundler/gem_tasks'

APP_RAKEFILE = File.expand_path("test/dummy/Rakefile", __dir__)
load 'rails/tasks/engine.rake'
load 'rails/tasks/statistics.rake'

require 'bundler/gem_tasks'

task default: :test
