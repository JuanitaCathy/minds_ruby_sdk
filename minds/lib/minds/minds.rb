require 'openai'
require 'uri'
require 'json'
require 'minds/exceptions'
require 'minds/datasources' 

module Minds
  DEFAULT_PROMPT_TEMPLATE = 'Use your database tools to answer the user\'s question: {{question}}'.freeze

  class Mind
    attr_accessor :name, :model_name, :provider, :parameters, :created_at, :updated_at, :datasources

    def initialize(client, name, model_name = nil, provider = nil, parameters = {}, datasources = nil, created_at = nil, updated_at = nil)
      @api = client.api
      @client = client
      @project = 'mindsdb'
      
      @name = name
      @model_name = model_name
      @provider = provider
      @parameters = parameters || {}
      @prompt_template = @parameters.delete('prompt_template') || nil
      @created_at = created_at
      @updated_at = updated_at
      @datasources = datasources
    end

    def update(name: nil, model_name: nil, provider: nil, prompt_template: nil, datasources: nil, parameters: nil)
      data = {}

      if datasources
        ds_names = datasources.map { |ds| @client.minds.check_datasource(ds) }
        data['datasources'] = ds_names
      end

      data['name'] = name if name
      data['model_name'] = model_name if model_name
      data['provider'] = provider if provider
      data['parameters'] = parameters || {}

      data['parameters']['prompt_template'] = prompt_template if prompt_template

      @api.patch("/projects/#{@project}/minds/#{@name}", data: data)
      
      @name = name if name && name != @name
    end

    def add_datasource(datasource)
      ds_name = @client.minds.check_datasource(datasource)

      @api.post("/projects/#{@project}/minds/#{@name}/datasources", data: { 'name' => ds_name })

      updated = @client.minds.get(@name)
      @datasources = updated.datasources
    end

    def del_datasource(datasource)
      datasource = datasource.name if datasource.is_a?(Datasource)

      raise ArgumentError, "Unknown type of datasource: #{datasource}" unless datasource.is_a?(String)

      @api.delete("/projects/#{@project}/minds/#{@name}/datasources/#{datasource}")

      updated = @client.minds.get(@name)
      @datasources = updated.datasources
    end

    def completion(message, stream: false)
      parsed = URI.parse(@api.base_url)

      netloc = parsed.host
      llm_host = netloc == 'mdb.ai' ? 'llm.mdb.ai' : "ai.#{netloc}"

      parsed.host = llm_host
      parsed.path = ''

      base_url = parsed.to_s
      openai_client = OpenAI::Client.new(access_token: @api.api_key, uri_base: base_url)

      response = openai_client.chat(
        parameters: {
          model: @name,
          messages: [{ role: 'user', content: message }],
          stream: stream
        }
      )

      stream ? stream_response(response) : response.choices[0].message.content
    end

    private

    def stream_response(response)
      response.each do |chunk|
        yield chunk.choices[0].delta
      end
    end
  end

  class Minds
    def initialize(client)
      @api = client.api
      @client = client
      @project = 'mindsdb'
    end

    def list
      data = @api.get("/projects/#{@project}/minds").json
      data.map { |item| Mind.new(@client, **item) }
    end

    def get(name)
      response = @api.get("/projects/#{@project}/minds/#{name}")
      item = response.parsed_response
      Mind.new(@client, **item)
    end

    def check_datasource(ds)
      case ds
      when Datasource
        ds.name
      when DatabaseConfig
        begin
          @client.datasources.get(ds.name)
        rescue Minds::ObjectNotFound
          @client.datasources.create(ds)
        end
        ds.name
      else
        raise ArgumentError, "Unknown type of datasource: #{ds}"
      end
    end

    def create(name:, model_name: nil, provider: nil, prompt_template: nil, datasources: nil, parameters: {}, replace: false)
      drop(name) if replace && (get(name) rescue nil)

      ds_names = datasources&.map { |ds| check_datasource(ds) } || []

      parameters['prompt_template'] ||= DEFAULT_PROMPT_TEMPLATE
      parameters['prompt_template'] = prompt_template if prompt_template

      @api.post("/projects/#{@project}/minds", {
        'name' => name,
        'model_name' => model_name,
        'provider' => provider,
        'parameters' => parameters,
        'datasources' => ds_names
      })

      get(name)
    end

    def drop(name)
      @api.delete("/projects/#{@project}/minds/#{name}")
    end
  end
end