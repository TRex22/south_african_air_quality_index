#  South African Air Quality Index
A client for the South African Air Quality Index (SAAQIS)
This is an unofficial project and still a work in progress (WIP) ... more to come soon.

Based on this website: https://saaqis.environment.gov.za/

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'south_african_air_quality_index'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install south_african_air_quality_index

## Usage

```ruby
  require 'south_african_air_quality_index'
  client  = SouthAfricanAirQualityIndex::Client.new

  # To list stations and available monitors:
  client.stations

  # To get the correct list of info for reports
  station_names = ['City of Johannesburg', 'City of Ekurhuleni', 'City of Cape Town']
  client.selected_stations(station_names, build_for_response: true)

  # To get a report from one stations
  # Some defaults that are used:
  # interval: DEFAULT_INTERVAL (60)
  # report_type: REPORT_TYPE (average)
  #
  # station_name - will do a best match to the name
  # start_date - can be a Time, DateTime or string 30/01/2022 00:00
  # end_date - can be a Time, DateTime or string 30/01/2022 00:00
  station_name = 'City of Ekurhuleni'
  start_date = Time.now - (60 * 60)
  end_date = Time.now
  client.station_report(station_name, start_date, end_date)

  # To get a report from multiple stations at once (HTML is returned for now)
  # Some defaults that are used:
  # interval: DEFAULT_INTERVAL (60)
  # report_type: REPORT_TYPE (average)
  #
  # station_names - will do a best match to the name
  # start_date - can be a Time, DateTime or string 30/01/2022 00:00
  # end_date - can be a Time, DateTime or string 30/01/2022 00:00
  station_names = ['City of Johannesburg', 'City of Ekurhuleni', 'City of Cape Town']
  start_date = Time.now - (60 * 60)
  end_date = Time.now
  client.multi_station_report(station_names, start_date, end_date)
```

### Endpoints
- Stations
- GetStationReportData
- GetMultiStationReportData

Other endpoints have not been implemented.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Tests
To run tests execute:

    $ rake test

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/trex22/south_african_air_quality_index. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SouthAfricanAirQualityIndex: project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/trex22/south_african_air_quality_index/blob/master/CODE_OF_CONDUCT.md).
