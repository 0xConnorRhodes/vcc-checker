def fzf(collection, args = '')
  io = IO.popen('fzf ' + args, 'r+')
  begin
    collection.each { |item| io.puts(item) }
    io.close_write
    io.readlines.map(&:chomp)
  ensure
    io.close_write unless io.closed?
  end
end