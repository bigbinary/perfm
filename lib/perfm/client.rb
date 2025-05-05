require "net/http"
require "json"

module Perfm
  class Client
    HTTPS = "https".freeze
    DEFAULT_TIMEOUT = 10

    def initialize(config)
      @api_url = config.api_url
      @api_key = config.api_key
      @timeout = DEFAULT_TIMEOUT
      @mutex = Mutex.new
      @connections = []
      @headers = {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@api_key}",
        "X-Perfm-Version" => Perfm::VERSION,
      }
    end

    def post(path, data)
      uri = URI(@api_url + path)
      request = Net::HTTP::Post.new(uri.path, @headers)
      request.body = data.to_json
      transmit(request)
    end

    private

    def transmit(request)
      http = take_connection
      response = http.request(request)
      handle_response(response)
    rescue => e
      puts "HTTP Error: #{e.message}"
    ensure
      release_connection(http) if http
    end

    def take_connection
      @mutex.synchronize do
        if conn = @connections.pop
          conn.start unless conn.started?
          conn
        else
          create_connection
        end
      end
    end

    def release_connection(conn)
      @mutex.synchronize { @connections << conn }
    end

    def create_connection
      uri = URI(@api_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == HTTPS
      http.open_timeout = @timeout
      http.read_timeout = @timeout
      http
    end

    def handle_response(response)
      case response
      when Net::HTTPSuccess
        true
      when Net::HTTPUnauthorized
        puts "Invalid API key"
        false
      else
        puts "Unexpected response: #{response.code}"
        false
      end
    end
  end
end
