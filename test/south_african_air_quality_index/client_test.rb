require "test_helper"

class SouthAfricanAirQualityIndexTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil SouthAfricanAirQualityIndex::VERSION
  end

  def test_that_the_client_has_compatible_api_version
    assert_equal 'v1', SouthAfricanAirQualityIndex::Client.compatible_api_version
  end

  def test_that_the_client_has_api_version
    assert_equal 'v1 2022-07-08', SouthAfricanAirQualityIndex::Client.api_version
  end
end
