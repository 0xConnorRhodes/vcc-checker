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
      hash.merge("Count" => occurrences.size)
    end
    result = normalize_data result
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

    hcl_arr = normalize_data hcl_arr

    # check data for hcl compatibility and pull in relevant data
    data.each do |device|
      hcl_arr.each do |hcl_dev|
        if hcl_dev["Manufacturer"] == device["Manufacturer"] && hcl_dev["Model"] == device["Model"]
          device["HCL"] = 'TRUE'
          device["Min FW Version"] = hcl_dev["Minimum Firmware Supported"]
          device["Notes"] = hcl_dev["Notes"]
          break # needed since this loop is for every hcl_dev, not every device
        else
          device["HCL"] = 'FALSE'
          device["Min FW Version"] = nil
          device["Notes"] = nil
        end
      end
    end

    return data
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

  private
    def normalize_data data
      manufacturer_remaps = {
        "Axis Communications" => "Axis",
        "Arecont Vision" => "Arecont",
        "Hanwha Techwin" => "Hanwha",
        "HANWHA TECHWIN" => "Hanwha"
      }

      field_remaps = {
        "Model Name" => "Model",
        "MODEL" => "Model",
        "MANUFACTURER" => "Manufacturer"
      }

      field_remaps.each do |old_field, new_field|
        data.each do |device|
          device[new_field] = device.delete(old_field) if device.key? old_field
        end
      end

      manufacturer_remaps.each do |old_name, new_name|
        data.each do |device|
          device["Manufacturer"] = new_name if device["Manufacturer"] == old_name
        end
      end

      return data
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
data = data_hcl

# optional code to sum a field if utilized channels per individual camera is included in raw data
# channel_counts = []
# data.each do |model|
#   model["Total Channel Count"] = 0

#   data_raw.each do |cam|
#     model["Total Channel Count"] += cam["CHANNEL"].to_i if cam["MODEL"] == model["Model"]
#   end
# end

vcc.write_output_file data, opts[:output]

puts `head #{opts[:output]} | column -t -s ','`

# tally code



binding.pry