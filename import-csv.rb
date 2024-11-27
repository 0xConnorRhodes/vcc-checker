require 'csv'
require 'pp'
require 'slop'
require_relative 'lib/fzf'
require 'pry'

class VccChecker
  def import csv_file
    hash_array = []
    CSV.foreach(csv_file, headers: true) do |row|
      hash_array << row.to_h.transform_keys(&:upcase)
    end
    return hash_array
  end

  def parse_args
    opts = Slop.parse do |o|
      o.string '-i', '--input', 'input csv'
      o.string '-o', '--output', 'output csv', default: 'output.csv'
      o.string '-h', '--hcl', 'Hardware Compatibility List CSV: verkada.com/security-cameras/command-connector/hcl'
    end
    if !opts.input?
      puts opts
      exit
    end
    return opts
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
    result = data.group_by(&:itself).map do |hash, occurrences|
      hash.merge("COUNT" => occurrences.size)
    end
    return result
  end

  def check_hcl data, hcl
    # remove intro comments in hcl.csv
    first_line = File.open(hcl, 'r') {|f| f.readline.chomp}
    if first_line != 'Manufacturer,Model Name,Minimum Firmware Supported,Notes'
      `sed -i '1,4d' #{hcl}` 
    end


    hcl_arr = []
    CSV.foreach(hcl, headers: true) do |row|
      hcl_arr << row.to_h
    end
    hcl_arr.each {|hash| hash.delete(nil)}

    manufacturer_remaps = {
      "Axis Communications" => "Axis",
      "Arecont Vision" => "Arecont",
      "Hanwha Techwin" => "Hanwha"
    }

    field_remaps = {
      "Model Name" => "Model"
    }

    manufacturer_remaps.each do |remap|
      hcl_arr.each do |device|
          device["Manufacturer"] = remap[1] if device["Manufacturer"] == remap[0]
      end
    end

    field_remaps.each do |remap|
      hcl_arr.each do |device|
        device[remap[1]] = device.delete(remap[0])
      end
    end

    # return data
    return hcl_arr # debug
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

vcc = VccChecker.new
opts = vcc.parse_args

data_raw = vcc.import opts[:input]

vcc.show_example_data data_raw

attributes = vcc.choose_filter_attributes data_raw
data_filtered = vcc.filter_by_attributes data_raw, attributes
data_uniq = vcc.count_duplicate_lines data_filtered

data_hcl = opts.hcl? ? (vcc.check_hcl data_uniq, opts[:hcl]) : data_uniq

# data = data_hcl
data = data_uniq # debug

vcc.write_output_file data, opts[:output]

puts `head #{opts[:output]} | column -t -s ','`

binding.pry