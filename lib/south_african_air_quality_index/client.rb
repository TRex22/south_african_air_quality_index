module SouthAfricanAirQualityIndex
  class Client
    include ::SouthAfricanAirQualityIndex::Constants
    include ::SouthAfricanAirQualityIndex::Community

    # TODO: Air quality guidelines
    # TODO: Units breakdown
    # TODO: Return codes
    # https://api-docs.iqair.com/?version=latest
    # Below are a few example of return codes you may get. This list is not exhaustive.
    # success: returned when JSON file was generated successfully.
    # call_limit_reached: returned when minute/monthly limit is reached.
    # api_key_expired: returned when API key is expired.
    # incorrect_api_key: returned when using wrong API key.
    # ip_location_failed: returned when service is unable to locate IP address of request.
    # no_nearest_station: returned when there is no nearest station within specified radius.
    # feature_not_available: returned when call requests a feature that is not available in chosen subscription plan.
    # too_many_requests: returned when more than 10 calls per second are made.

    attr_reader :api_key,
      :base_path,
      :port,
      :login_response,
      :raw_cookie,
      :expiry

    def initialize(api_key:, base_path: BASE_PATH, port: 80)
      @api_key = api_key
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

    private

    def authorise_and_send(http_method:, path:, payload: {}, params: {})
      params.merge!({ key: api_key })

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

    def process_params(params)
      params.keys.map { |key| "#{key}=#{params[key]}" }.join('&')
    end
  end
end
