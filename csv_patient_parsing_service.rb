require "minitest/autorun"


class ApplicationService
  def self.call(*args, &block)
    new(*args, &block).call
  end
end

class CsvPatientParsingService < ApplicationService
    def initialize(file_path, test_mode=false)
    end
    def call
    end
end

class CsvPatientParsingServiceTest < Minitest::Test
  def setup
    @result = CsvPatientParsingService.call('input_test.csv', true)
  end

  def test_valid_output_rows
    assert_equal [["Antonio", "Brown", "1966-02-02", "890887", "2019-09-30", "2000-09-30", "+13033339987"], ["Baker", "Mayfield", "2088-01-04", "349093", "2019-09-30", "2050-12-13", "+13039873345"], ["Serena", "Williams", "1948-04-04", "jk 909009", "2017-11-11", "2050-12-14", "+14445559876"], ["Jake", "Jabs", "1988-01-06", "349090", "2019-09-30", "2050-12-15", "+14445559877"], ["Mary", "Poppins", "1988-01-07", "uu 90990", "2019-09-30", "2050-12-16", "+14445559878"], ["Sally", "Jesse Rephael", "2088-01-08", "349097", "2019-09-30", "2050-12-17", "+14445559879"], ["Jason", "Statham", "1988-02-12", "349099", "2019-09-30", nil, "+16065559886"], ["Lenny", "Bruce", "2088-01-11", "349100", "2019-09-30", nil, "+12025559882"]], @result.output_rows
  end
  
  def test_malformed_rows
    assert_equal [["Jason", "Bateman", nil, "AB 0000", nil, nil, nil], ["Brent", "Wilson", "1/1/19888", "349090", "2019-09-30", "2000-09-30", "+13038873456"], ["Antonio", "Brown", "1966-02-02", "890887", "2019-09-30", "2000-09-30", "+13033339987"], ["Jerry", "Jones", "2099-06-06", "jkj3343", "2016-08-04", "2050-12-12", nil], ["Baker", "Mayfield", "2088-01-04", "349093", "2019-09-30", "2050-12-13", "+13039873345"], ["Serena", "Williams", "1948-04-04", "jk 909009", "2017-11-11", "2050-12-14", "+14445559876"], ["Jake", "Jabs", "1988-01-06", "349090", "2019-09-30", "2050-12-15", "+14445559877"], ["Mary", "Poppins", "1988-01-07", "uu 90990", "2019-09-30", "2050-12-16", "+14445559878"], ["Sally", "Jesse Rephael", "2088-01-08", "349097", "2019-09-30", "2050-12-17", "+14445559879"], ["Bruce", nil, "2088-01-09", "234324", "2019-09-30", nil, "+14445559880"], ["Jason", "Statham", "1988-02-12", "349099", "2019-09-30", nil, "+16065559886"], ["Lenny", "Bruce", "2088-01-11", "349100", "2019-09-30", nil, "+12025559882"], [nil, "Short", "2088-01-12", "349101", "2019-09-30", nil, "+14045559883"], ["Benny", "Samson", "2088-01-13", "349102", "2019-09-30", nil, "44425"]] ,   @result.malformed_rows.keys
  end
end
