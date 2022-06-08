module SouthAfricanAirQualityIndex
  module Constants
    BASE_PATH = 'https://saaqis.environment.gov.za'

    DEFAULT_INTERVAL = 60
    STATION_REPORT = 'station report'.freeze
    HOURLY_REPORT = 'hourly report'.freeze
    REPORT_TYPE = 'Average'.freeze

    # https://api-docs.iqair.com/?version=latest#important-notes
    # https://www.airnow.gov/aqi/aqi-basics/
    # https://www.weather.gov/safety/airquality-aqindex
    AQI_INDEX = {
      good: { lowest_level: 0, highest_level: 50, colour: 'green', description: 'Air quality is satisfactory, and air pollution poses little or no risk.' },
      moderate: { lowest_level: 51, highest_level: 100, colour: 'yellow', description: 'Air quality is acceptable. However, there may be a risk for some people, particularly those who are unusually sensitive to air pollution.' },
      unhealthy_for_sensitive_groups: { lowest_level: 101, highest_level: 150, colour: 'orange', description: 'Members of sensitive groups may experience health effects. The general public is less likely to be affected.' },
      unhealthy: { lowest_level: 151, highest_level: 200, colour: 'red', description: 'Some members of the general public may experience health effects; members of sensitive groups may experience more serious health effects.' },
      very_unhealthy: { lowest_level: 201, highest_level: 300, colour: 'purple', description: 'Health alert: The risk of health effects is increased for everyone.' },
      hazardous: { lowest_level: 301, highest_level: 1000, colour: 'maroon', description: 'Health warning of emergency conditions: everyone is more likely to be affected.' }
    }

    def calculate_aqi_range(key)
      value = AQI_INDEX[:key]
      (value.lowest_level..value.highest_level).to_a
    end
  end
end
