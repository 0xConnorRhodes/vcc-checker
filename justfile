set shell := ["ruby", "-e"]

test:
  `rm test/output.csv` if File.exist? 'test/output.csv'
  exec('ruby import-csv.rb -i test/test.csv -o test/output.csv')
  `cp test/output.csv /out/dwn`

test-hcl:
  `rm test/output.csv` if File.exist? 'test/output.csv'
  exec('ruby import-csv.rb -i test/test.csv -o test/output.csv -h test/hcl.csv')
  `cp test/output.csv /out/dwn`
