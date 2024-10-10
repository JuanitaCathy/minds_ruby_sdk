require 'httparty'
require 'json'
require 'minds/exceptions'

class Minds::RestAPI
  include HTTParty
  attr_accessor :base_url, :api_key

  def initialize(api_key, base_url = nil)
    @base_url = base_url.nil? ? 'https://mdb.ai' : base_url.rstrip
    @base_url += '/api' unless @base_url.end_with?('/api')
    @api_key = api_key
  end

  private

  def headers
    {
      'Authorization' => "Bearer #{@api_key}",
      'Content-Type' => 'application/json'
    }
  end

  public

  def get(url)
    response = self.class.get("#{@base_url}#{url}", headers: headers)
    raise_for_status(response)
    response
  end

  def delete(url)
    response = self.class.delete("#{@base_url}#{url}", headers: headers)
    raise_for_status(response)
    response
  end

  def post(url, data)
    response = self.class.post(
      "#{@base_url}#{url}",
      headers: headers,
      body: data.to_json
    )
    raise_for_status(response)
    response
  end

  def patch(url, data)
    response = self.class.patch(
      "#{@base_url}#{url}",
      headers: headers,
      body: data.to_json
    )
    raise_for_status(response)
    response
  end

  private

  def raise_for_status(response)
    case response.code
    when 404
      raise Minds::ObjectNotFound.new(response.body)
    when 403
      raise Minds::Forbidden.new(response.body)
    when 401
      raise Minds::Unauthorized.new(response.body)
    when 400..599
      raise Minds::UnknownError.new("#{response.message}: #{response.body}")
    end
  end
end
