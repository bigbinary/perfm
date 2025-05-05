require_relative "lib/perfm/version"

Gem::Specification.new do |spec|
  spec.name = "perfm"
  spec.version = Perfm::VERSION
  spec.authors = ["Vishnu M"]
  spec.email = ["vishnu.m@bigbinary.com"]

  spec.summary = "Everything Rails performance monitoring"
  spec.description = "Monitor Rails application performance metrics"
  spec.homepage = "https://github.com/vishnu-m/perfm"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/master/CHANGELOG.md"
  }

  spec.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]
  
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "anyway_config", ">= 1.3", "< 3"
  spec.add_dependency "sidekiq", ">= 6.0"
  spec.add_dependency "rbtrace", "~> 0.5"
  spec.add_dependency "gvl_timing"
  
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
end
