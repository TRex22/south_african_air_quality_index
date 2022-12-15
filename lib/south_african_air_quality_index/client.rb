module SouthAfricanAirQualityIndex
  class Client
    include ::SouthAfricanAirQualityIndex::Constants

    attr_reader :base_path, :port, :stations

    def initialize(base_path: BASE_PATH, port: 80)
      @base_path = base_path
      @port = port
    end

    def self.compatible_api_version
      'v1'
    end

    # This is the version of the API docs this client was built off-of
    def self.api_version
      'v1 2022-12-15'
    end

    # Endpoints

    # Memoize stations as they are unlikely to change often
    def stations
      # This endpoint is no longer active:
      @stations ||= send(http_method: :get, path: 'ajax/getAllStations')
    end

    def stations_from_code(codes, build_for_response: false)
      stations['body']['Stations'].select do |station|
        codes.map(&:to_s).include?(station["serialCode"].to_s)
      end
    end

    def selected_stations(station_names)
      stations['body'].select do |station|
        station_matches?(station_names, station)
      end
    end

    def station_report(station_name, start_date, end_date, interval: DEFAULT_INTERVAL, report_type: REPORT_TYPE)
      station = selected_stations([station_name]).first
      return if station.empty?

      monitor_ids = fetch_monitor_ids(station)

      body = {
        "StationId": station['serialCode'],
        "MonitorsChannels": monitor_ids,
        "reportName": STATION_REPORT,
        "startDateAbsolute": start_date.to_s,
        "endDateAbsolute": end_date.to_s,
        "startDate": start_date.to_s,
        "endDate": end_date.to_s,
        "reportType": report_type,
        "fromTb": 60,
        "toTb": 60
      }.to_json

      send(http_method: :get, path: 'report/GetStationReportData', body: body, params: { 'InPopUp': false })
    end

    def multi_station_report(station_names, start_date, end_date, interval: DEFAULT_INTERVAL, report_type: REPORT_TYPE)
      extracted_stations = selected_stations(station_names)

      monitor_channels_by_station_id = extracted_stations.map { |station|
        [station['serialCode'].to_s, fetch_monitor_ids(station)]
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

      send(http_method: :get, path: 'report/GetMultiStationReportData', body: body.to_json)
    end

    private

    def send(http_method:, path:, body: {}, params: {})
      start_time = micro_second_time

      response = HTTParty.send(
        http_method.to_sym,
        construct_base_path(path, params),
        body: body,
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
        monitor['channel']
      end
    end

    def process_station(name)
      name.to_s.downcase.gsub('  ', ' ')
    end
  end
end
