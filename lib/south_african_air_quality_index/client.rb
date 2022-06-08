module SouthAfricanAirQualityIndex
  class Client
    include ::SouthAfricanAirQualityIndex::Constants

    attr_reader :base_path, :port

    def initialize(base_path: BASE_PATH, port: 80)
      @base_path = base_path
      @port = port
    end

    def self.compatible_api_version
      'v1'
    end

    # This is the version of the API docs this client was built off-of
    def self.api_version
      'v1 2022-06-08'
    end

    # Endpoints
    def stations
      send(http_method: :get, path: 'ajax/getAllStationsNew')
    end

    def selected_stations(station_names)

    end

    def station_report()

    end

    def multi_station_report()

    end

    private

    def send(http_method:, path:, payload: {}, params: {})
      start_time = micro_second_time

      response = HTTParty.send(
        http_method.to_sym,
        construct_base_path(path, params),
        body: payload,
        headers: { 'Content-Type': 'application/json' },
        port: port,
        format: :json
      )

      end_time = micro_second_time
      construct_response_object(response, path, start_time, end_time)
    end

    def construct_response_object(response, path, start_time, end_time)
      {
        'body' => parse_body(response, path),
        'headers' => response.headers,
        'metadata' => construct_metadata(response, start_time, end_time)
      }
    end

    def construct_metadata(response, start_time, end_time)
      total_time = end_time - start_time

      {
        'start_time' => start_time,
        'end_time' => end_time,
        'total_time' => total_time
      }
    end

    def micro_second_time
      (Time.now.to_f * 1_000_000).to_i
    end

    def construct_base_path(path, params)
      constructed_path = "#{base_path}/#{path}"

      if params == {}
        constructed_path
      else
        "#{constructed_path}?#{process_params(params)}"
      end
    end

    def parse_body(response, path)
      JSON.parse(response.body) # Purposely not using HTTParty
    rescue JSON::ParserError => _e
      response.body
    end

    def process_params(params)
      params.keys.map { |key| "#{key}=#{params[key]}" }.join('&')
    end
  end
end
