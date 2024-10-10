require 'minds/rest_api'
require 'minds/datasources'
require 'minds/minds'

module Minds
  class Client
    attr_reader :api, :datasources, :minds

    def initialize(api_key, base_url = nil)
      @api = RestAPI.new(api_key, base_url)
      @datasources = Datasources.new(self)
      @minds = Minds.new(self)
    end
  end
end
