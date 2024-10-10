# frozen_string_literal: true

require_relative "minds/version"
require_relative 'minds/client'
require_relative 'minds/datasources'
require_relative 'minds/minds'
require_relative 'minds/rest_api'

module Minds
  class Error < StandardError; end
  # Your code goes here...
end
