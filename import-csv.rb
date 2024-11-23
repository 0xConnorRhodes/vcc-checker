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
    pp raw_data[0]
    puts ''
    puts "Press Enter to continue..."
    STDIN.gets
  end

  def filter_by_attributes data, keys
    filtered_data = data.map do |hash|
      hash.slice(*keys)
    end
    return filtered_data
  end

  def choose_filter_attributes data
    keys_arr = data[0].keys
    keys = fzf(keys_arr, '-m')
  end

  def write_output_file data
    csv_file = 'output.csv'
    if File.exist?(csv_file)
      puts "file #{csv_file} exists. Overwrite? y/n"
      choice = STDIN.gets.strip.downcase
      return if choice != 'y' # exit method without writing if choice != y
    end

    CSV.open(csv_file, 'w') do |csv|
      # Write the headers
      csv << data.first.keys

      # Write the data
      data.each do |hash|
        csv << hash.values
      end
    end
    puts "Wrote #{csv_file}\n\n"
    return csv_file
  end
end

csv_file = ARGV[0]

csv = ImportCsv.new

raw_data = csv.import csv_file
csv.show_example_data raw_data

attributes = csv.choose_filter_attributes raw_data
data_filtered = csv.filter_by_attributes raw_data, attributes

data = data_filtered.uniq

output_file = csv.write_output_file data

puts `head #{output_file} | column -t -s ','`

# binding.pry