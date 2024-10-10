# frozen_string_literal: true

require_relative "lib/minds/version"

Gem::Specification.new do |spec|
  spec.name = "minds"
  spec.version = Minds::VERSION
  spec.authors = ["K Om Senapati"]
  spec.email = ["komnoob123@gmail.com"]

  spec.summary = "Minds SDK for Ruby users"
  spec.homepage = "https://github.com/JuanitaCathy/mindsdb_ruby_sdk"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/JuanitaCathy/mindsdb_ruby_sdk"
  
  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty"
  spec.add_dependency "activemodel"
  spec.add_dependency "ruby-openai"
end
