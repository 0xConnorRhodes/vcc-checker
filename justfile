set shell := ["ruby", "-e"]

test:
  `rm output.csv` if File.exist? 'output.csv'
  exec('ruby import-csv.rb test.csv')