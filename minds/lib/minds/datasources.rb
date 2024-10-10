require 'minds/exceptions'
require 'active_model' 

module Minds
  class DatabaseConfig
    include ActiveModel::Model

    attr_accessor :name, :engine, :description, :connection_data, :tables

    validates :name, presence: true
    validates :engine, presence: true
    validates :description, presence: true

    def initialize(attributes = {})
      super
      @connection_data ||= {}
      @tables ||= []
    end

    def to_h
      {
        name: @name,
        engine: @engine,
        description: @description,
        connection_data: @connection_data,
        tables: @tables
      }
    end
  end

  class Datasource < DatabaseConfig
  end

  class Datasources
    def initialize(client)
      @api = client.api
    end

    def create(ds_config, replace = false)
      raise ArgumentError, "Invalid Datasource Configuration" unless ds_config.is_a?(DatabaseConfig)

      name = ds_config.name

      if replace
        begin
          get(name)
          drop(name)
        rescue Minds::ObjectNotFound
        end
      end

      @api.post('/datasources', data: ds_config.to_h)
      get(name)
    end

    def list
      data = @api.get('/datasources').json
      ds_list = []

      data.each do |item|
        next if item['engine'].nil? 
        ds_list << Datasource.new(item)
      end

      ds_list
    end

    def get(name)
      data = @api.get("/datasources/#{name}").json

      raise Minds::ObjectNotSupported, "Wrong type of datasource: #{name}" if data['engine'].nil?
      Datasource.new(data)
    end

    def drop(name)
      @api.delete("/datasources/#{name}")
    end
  end
end