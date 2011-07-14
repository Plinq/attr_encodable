require 'rake'
begin
  require 'rspec/core'
  require 'rspec/core/rake_task'
rescue MissingSourceFile 
  module RSpec
    module Core
      class RakeTask
        def initialize(name)
          task name do
            # if rspec-rails is a configured gem, this will output helpful material and exit ...
            require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

            # ... otherwise, do this:
            raise <<-MSG

#{"*" * 80}
*  You are trying to run an rspec rake task defined in
*  #{__FILE__},
*  but rspec can not be found. Try running 'gem install rspec'.
#{"*" * 80}
MSG
          end
        end
      end
    end
  end
end

Rake.application.instance_variable_get('@tasks').delete('default')

task :default => :spec

desc "Run all specs in spec directory"
RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  desc  "Run all specs with rcov"
  RSpec::Core::RakeTask.new(:coverage) do |t|
    t.pattern = 'spec/**/*_spec.rb'
    t.rcov = true
    t.rcov_opts = %w{--exclude osx\/objc,gems\/,spec\/,features\/}
    t.verbose = true
  end
end

require "jeweler"
Jeweler::Tasks.new do |gemspec|
  gemspec.name = "attr_encodable"
  gemspec.summary = "An attribute black- or white-list for ActiveRecord serialization"
  gemspec.files = Dir["{lib}/**/*", "LICENSE", "README.md"]
  gemspec.description = %{
    attr_encodable enables you to set up defaults for what is included or excluded when you serialize an ActiveRecord object. This is especially useful for protecting private attributes when building a public API.
  }
  gemspec.email = "flip@x451.com"
  gemspec.homepage = "http://github.com/Plinq/attr_encodable"
  gemspec.authors = ["Flip Sasser"]
  gemspec.test_files = Dir["{spec}/**/*"]
  gemspec.add_development_dependency 'rcov', '>= 0.9.9'
  gemspec.add_development_dependency 'rspec', '>= 2.0'
  gemspec.add_dependency 'redis', '>= 2.1.1'
end
