require 'csv'
require 'pp'
require_relative 'lib/fzf'
require 'pry'

class ImportCsv
  def import csv_file
    hash_array = []
    CSV.foreach(csv_file, headers: true) do |row|
      hash_array << row.to_h
    end
    return hash_array
  end

  def show_example_data raw_data
    puts 'Example data from CSV:'
    pp raw_data.first
    puts ''
    puts "Press Enter to continue..."
    STDIN.gets
  end

  def choose_filter_attributes data
    keys_arr = data.first.keys
    keys = fzf(keys_arr, '-m')
  end

  def filter_by_attributes data, keys
    filtered_data = data.map do |hash|
      hash.slice(*keys)
    end
    return filtered_data
  end

  def count_duplicate_lines data
    data = data.uniq
  end

  def write_output_file data, out_file
    if File.exist?(out_file)
      puts "file #{out_file} exists. Overwrite? y/n"
      choice = STDIN.gets.strip.downcase
      return if choice != 'y' # exit method without writing if choice != y
    end

    CSV.open(out_file, 'w') do |csv|
      # Write the headers
      csv << data.first.keys

      # Write the data
      data.each do |hash|
        csv << hash.values
      end
    end
    puts "Wrote #{out_file}\n\n"
  end
end

in_file = ARGV.first
out_file = 'output.csv'

vcc = ImportCsv.new

raw_data = vcc.import in_file

vcc.show_example_data raw_data

attributes = vcc.choose_filter_attributes raw_data
data_filtered = vcc.filter_by_attributes raw_data, attributes
data = vcc.count_duplicate_lines data_filtered

vcc.write_output_file data, out_file

puts `head #{out_file} | column -t -s ','`

# binding.pry