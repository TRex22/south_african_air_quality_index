module SouthAfricanAirQualityIndex
  class Client
    include ::SouthAfricanAirQualityIndex::Constants

    attr_reader :base_path, :port, :stations

    def initialize(base_path: BASE_PATH, port: BASE_PORT)
      @base_path = base_path
      @port = port
      @cookie = authorise
    end

    def self.compatible_api_version
      'v1'
    end

    # This is the version of the API docs this client was built off-of
    def self.api_version
      'v1 2024-03-18'
    end

    # Endpoints
    def regions
      return @regions if @regions

      response = send_request(http_method: :get, path: '/v1/envista/regions', port: DATA_SOURCE_PORT, port_in_path: true)

      if response["code"] != 200
        puts "Fallback SAAQIS region fetch!"
        @regions ||= fetch_regions_from_html
      else
        @regions ||= response["body"]
      end
    end

    def fetch_regions_from_html
      # https://saaqis.environment.gov.za/Report/HourlyReports
      response = send_request(http_method: :get, path: 'Report/HourlyReports')
      doc = Nokogiri::HTML(response["body"])

      # JSON.parse(content).map { |j| j.dig("stations")}.flatten
      # alex = JSON.parse(content).map { |j| j.dig("stations")}.flatten.select { |st| st["name"] == "Alexandra-NAQI" }.first
      find_and_parse_m_regions(doc)
    end

    # Memoize stations as they are unlikely to change often
    def stations
      # This endpoint is no longer active:
      # @stations ||= send_request(http_method: :get, path: 'ajax/getAllStations')

      @stations ||= regions.map { |regions| regions["stations"] }.flatten.uniq
    end

    def stations_from_code(codes, build_for_response: false)
      unless codes.is_a?(Array)
        codes = [codes]
      end

      stations.select do |station|
        codes.map(&:to_s).include?(station["stationId"].to_s)
      end
    end

    def selected_stations(station_names)
      unless station_names.is_a?(Array)
        station_names = [station_names]
      end

      stations.select do |station|
        station_matches?(station_names, station)
      end
    end

    # This has been deprecated:
    # def station_report(station_name, start_date, end_date, interval: DEFAULT_INTERVAL, report_type: REPORT_TYPE)
    #   station = selected_stations([station_name]).first
    #   return if station.empty?

    #   monitor_ids = fetch_monitor_ids(station)

    #   body = {
    #     "StationId": station['stationId'],
    #     "MonitorsChannels": monitor_ids,
    #     "reportName": STATION_REPORT,
    #     "startDateAbsolute": start_date.to_s,
    #     "endDateAbsolute": end_date.to_s,
    #     "startDate": start_date.to_s,
    #     "endDate": end_date.to_s,
    #     "reportType": report_type,
    #     "fromTb": 60,
    #     "toTb": 60
    #   }.to_json

    #   send_request(http_method: :get, path: 'report/GetStationReportData', body: body, params: { 'InPopUp': false })
    # end

    # This now will only return HTML
    # TODO: Parse the HTML
    # May not work:
    def multi_station_report(station_names, start_date, end_date, interval: DEFAULT_INTERVAL, report_type: REPORT_TYPE)
      extracted_stations = selected_stations(station_names)

      monitor_channels_by_station_id = extracted_stations.map { |station|
        [station['stationId'].to_s, fetch_monitor_ids(station)]
      }.to_h

      body = {
        "monitorChannelsByStationId": monitor_channels_by_station_id,
        "reportName": HOURLY_REPORT,
        "startDateAbsolute": start_date.to_s,
        "endDateAbsolute": end_date.to_s,
        "startDate": "/Date(#{Time.parse(start_date.to_s).to_i})/",
        "endDate": "/Date(#{Time.parse(end_date.to_s).to_i})/",
        "reportType": REPORT_TYPE,
        "fromTb": DEFAULT_INTERVAL,
        "toTb": DEFAULT_INTERVAL
      }

      monitor_channels_by_station_id.each.with_index do |pair, index|
        hsh = {
          "monitorChannelsByStationId[#{index}].Key": pair[0],
          "monitorChannelsByStationId[#{index}].Value": pair[1]
        }

        body = body.merge(hsh)
      end

      send_request(http_method: :get, path: 'report/MultiStationTable', body: body.to_json)
    end

    def station_average_report(station_name, start_date, end_date, interval: DEFAULT_INTERVAL, report_type: REPORT_TYPE, precent_valid: DEFAULT_PERCENT_VALID)
      station = selected_stations([station_name]).first
      return if station.empty?

      params = {
        filterChannels: fetch_monitor_ids(station),
        from: parse_time(start_date.to_s),
        to: parse_time(end_date.to_s),
        fromTimebase: interval,
        toTimebase: interval,
        precentValid: precent_valid,
        timeBeginning: false,
        useBackWard: true,
        unitConversion: false,
        includeSummary: true,
        onlySummary: false,
      }

      path = "v1/envista/stations/#{station['stationId']}/#{report_type}"
      send_request(http_method: :get, path: path, params: params, port: DATA_SOURCE_PORT, port_in_path: true)
    end

    private

    def send_request(http_method:, path:, body: {}, params: {}, headers: {}, port: @port, port_in_path: false)
      start_time = micro_second_time

      headers["Cookie"] = @cookie

      response = HTTParty.send(
        http_method.to_sym,
        construct_base_path(path, params, port, port_in_path),
        body: body,
        headers: headers.merge({ 'Content-Type': 'application/json' }),
        port: port,
        format: :json
      )

      end_time = micro_second_time
      construct_response_object(response, path, start_time, end_time)
    end

    # Quick n dirty time parsing
    def parse_time(str_time)
      time_components = str_time.to_s.split(' ')

      # Have to leave out the timezone - #{time_components[2]}
      "#{time_components[0]}T#{time_components[1]}"
    end

    def construct_response_object(response, path, start_time, end_time)
      {
        'body' => parse_body(response, path),
        'code' => response.code,
        'cookies' => response.headers.dig('set-cookie'),
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

    def construct_base_path(path, params, port, port_in_path)
      if port_in_path
        constructed_path = "#{base_path}:#{port}/#{path}"
      else
        constructed_path = "#{base_path}/#{path}"
      end

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

    def station_matches?(station_names, station)
      station_names
        .compact
        .any? do |station_name|
          processed_name = process_station(station_name)

          process_station(station['ShortName']) == processed_name ||
            process_station(station['city']) == processed_name ||
            process_station(station['DisplayName']) == processed_name ||
            process_station(station['name']) == processed_name ||
            process_station(station['owner']) == processed_name ||
            process_station(station['location']) == processed_name # TODO: Each monitor has a name too
        end
    end

    def fetch_monitor_ids(station)
      station['monitors'].map do |monitor|
        monitor['channelId']
      end
    end

    def process_station(name)
      name.to_s.downcase.gsub('  ', ' ')
    end

    def find_and_parse_m_regions(doc)
      doc.xpath('//script').each do |script|
        if script.content.include?("m_Regions")
          content = script.content[/let\s+m_Regions\s*=\s*(.*?)\s*;/, 1]
          return JSON.parse(content) if content
        end
      end

      nil
    end

    def authorise
      generate_token(get_api_token)
    end

    # This is terrible. Unsure why there is a JWT, since there is no secret
    # and this is public information.
    def generate_token(api_token)
      headers = {
        'Authorization': "ApiToken #{api_token}",
        'Accept': "application/json",
        'Content-Length': '0',
        'Host': BASE_URI,
        # 'envi-data-source': 'SAAQIS_ENVISTA',
        # 'Access-Control-Allow-Origin': 'https://saaqis.environment.gov.za',
        # 'Access-Control-Allow-Credentials': 'true',
        # 'Authority': "#{BASE_URI}:#{DATA_SOURCE_PORT}",
      }

      res = send_request(http_method: :post, path: 'v1/GenerateToken', headers: headers, port: DATA_SOURCE_PORT, port_in_path: true)

      @cookie ||= res["cookies"].first
    end

    def get_api_token
      # Account/GetApiToken
      body = { "userName": "Guest" }
      res = send_request(http_method: :post, path: 'Account/GetApiToken', body: body.to_json)

      res.dig("body")
    end

    # Experimental stuff
    def generate_jwt
      # header = {
      #   "alg": "HS256",
      #   "typ": "JWT"
      # }

      time_now = Time.now

      payload = {
        "unique_name": "Guest",
        "nbf": time_now.to_i,
        "exp": (time_now + 3600).to_i,
        "iat": time_now.to_i
      }

      # IMPORTANT: set nil as password parameter
      # token = JWT.encode payload, nil, 'none'

      # hmac_secret = ""
      # token = JWT.encode payload, hmac_secret, 'HS256'

      # token = JWT.encode payload, nil, 'none', { typ: 'JWT' }
      # token = JWT.encode payload, nil, 'HS256', { typ: 'JWT' }

      hmac_secret = 'ApiToken '
      _token = JWT.encode payload, hmac_secret, 'HS256', { typ: 'JWT' }


      # Account/GetApiToken
      # v1/GenerateToken

      authorization = "ApiToken " + res
    end
  end
end
