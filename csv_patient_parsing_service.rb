require 'csv'
require 'date'
require "minitest/autorun"

=begin
# Instructions:
  1). call -> CsvPatientParsingService.call('input.csv')
  2). Check the newly created output.csv and report.txt located within the same directory as the script.
  3). Run ruby csv_patient_pasing_service.rb to run tests.
=end
class ApplicationService
  def self.call(*args, &block)
    new(*args, &block).call
  end
end

class CsvPatientParsingService < ApplicationService
   attr_reader :phone_fields, :mandatory_fields, :file_path,
     :header_index_map, :date_fields, :malformed_rows, :output_rows,
     :test_mode
   
   def initialize(file_path, test_mode=false)
     @file_path = file_path
     @malformed_rows = Hash.new{|h,k| h[k] = [] }.compare_by_identity
     @output_rows = []
     @phone_fields = [:phone_number]
     @test_mode = test_mode
     @mandatory_fields = [:first_name, :last_name, :dob,
       :member_id, :effective_date, :phone_number]
     @date_fields = [:effective_date, :dob, :expiry_date]
     @header_index_map = {}
   end

   def call
      csv = CSV.open(file_path, 'r:bom|utf-8')
      map_header_indexes(csv.readline)
      while (row = csv.readline) do
        trim_white_space_for_all_fields(row)
        validate_mandatory_fields(row)
        format_phone_numbers_to_e164(row)
        transform_date_columns_to_iso_8601(row)
        
        output_rows << row if malformed_rows[row].size == 0
      end
      csv.close

      write_output_to_file

      self
   end

   private
   
   def map_header_indexes(header_array)
     header_array.each_with_index do |header, index|
       header_index_map[header.to_sym] = index
     end
     
     mandatory_fields_missing = []

     mandatory_fields.each do |mf|
       mandatory_fields_missing << mf  if header_index_map[mf].nil?
     end

     if mandatory_fields_missing.size > 0
       raise "Mandatory field(s) missing in CSV: #{ mandatory_fields_missing.join(',') }"
     end

     header_index_map
    end

   def validate_mandatory_fields(row)
     mandatory_fields.each do |mf|
       if row[header_index_map[mf]] == '' || row[header_index_map[mf]].nil?
         malformed_rows[row] << [mf, 'is missing'].join(' ')
       end
     end
   end

   def trim_white_space_for_all_fields(row)
     row.each do |val|
       val.strip! if val
     end
   end

   def format_phone_numbers_to_e164(row)
     phone_fields.each do |pf|
       next if header_index_map[pf].nil? || row[header_index_map[pf]].nil?

       row[header_index_map[pf]].tr!('^0-9', '')

       if row[header_index_map[pf]].size < 10
         malformed_rows[row] << [pf, 'is less than 10 digits'].join(' ')
       elsif row[header_index_map[pf]].size == 10
        row[header_index_map[pf]] = '+' << '1' << row[header_index_map[pf]]
       else
         row[header_index_map[pf]] = '+' << row[header_index_map[pf]]
       end
     end
   end

   def transform_date_columns_to_iso_8601(row)
     date_fields.each do |df|
        next if header_index_map[df].nil? || row[header_index_map[df]].nil?

        date_array = row[header_index_map[df]].split(/\D+/)

        if date_array.size != 3
          malformed_rows[row] << [df, 'is malformed.'].join(' ')
        elsif date_array.first.size == 4
          row[header_index_map[df]] = date_array.join('-')
        elsif date_array.last.size == 4
          year =  date_array.last
          month = date_array.first.size == 1 ? '0' << date_array.first : date_array.first
          day =   date_array[1].size == 1 ?  '0' << date_array[1] : date_array[1]
          row[header_index_map[df]] = "#{year}-#{month}-#{day}"
        elsif date_array.last.size == 2
          year =  '20' << date_array.last
          month = date_array.first.size == 1 ? '0' << date_array.first : date_array.first
          day =   date_array[1].size == 1 ?  '0' << date_array[1] : date_array[1]
          row[header_index_map[df]] = "#{year}-#{month}-#{day}"
        else
           malformed_rows[row] << [df, 'is malformed.'].join(' ')
        end
     end
   end
   
   def write_output_to_file
     CSV.open(test_mode ? "output_test.csv" : "output.csv", "wb") do |csv|
       csv << [:first_name, :last_name, :dob, :member_id,
         :effective_date, :expiry_date, :phone_number]
       output_rows.each do |output_row|
        csv << output_row
       end
     end

     File.open(test_mode ? "report_test.txt" : "report.txt", "w") do |line|
       failure_count = 0
       malformed_rows.keys.each do |k|
         next if malformed_rows[k].size == 0
         failure_count  +=1
         line.write [k, malformed_rows[k]].flatten.to_s + "\n"
       end
       line.write "Success: #{output_rows.size}\n"
       line.write "Failure: #{failure_count}\n"
     end
   end
end

CsvPatientParsingService.call('input.csv')

CsvPatientParsingService.call('input_test.csv', true)


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
