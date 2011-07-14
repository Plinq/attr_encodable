# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{attr_encodable}
  s.version = "0.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Flip Sasser"]
  s.date = %q{2011-07-14}
  s.description = %q{
    attr_encodable enables you to set up defaults for what is included or excluded when you serialize an ActiveRecord object. This is especially useful for protecting private attributes when building a public API.
  }
  s.email = %q{flip@x451.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    "LICENSE",
    "README.md",
    "lib/attr_encodable.rb"
  ]
  s.homepage = %q{http://github.com/Plinq/attr_encodable}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{An attribute black- or white-list for ActiveRecord serialization}
  s.test_files = ["spec/attr_encodable_spec.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rcov>, [">= 0.9.9"])
      s.add_development_dependency(%q<rspec>, [">= 2.0"])
      s.add_runtime_dependency(%q<redis>, [">= 2.1.1"])
    else
      s.add_dependency(%q<rcov>, [">= 0.9.9"])
      s.add_dependency(%q<rspec>, [">= 2.0"])
      s.add_dependency(%q<redis>, [">= 2.1.1"])
    end
  else
    s.add_dependency(%q<rcov>, [">= 0.9.9"])
    s.add_dependency(%q<rspec>, [">= 2.0"])
    s.add_dependency(%q<redis>, [">= 2.1.1"])
  end
end

