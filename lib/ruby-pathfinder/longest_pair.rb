require_relative 'lib/graph'
require 'benchmark'

GRAPH_PATH = File.join(__dir__, 'data/graph.rbm')
graph, station_variants = Marshal.load(File.read(GRAPH_PATH))

puts "Loaded data."

def clear_line
  terminal_size = `stty size`.split[-1].to_i
  print "\r" + " " * terminal_size + "\r"
end

def remaining(seconds)
  return "n/c" if seconds == -1

  hours = seconds / 3600
  seconds -= hours * 3600
  minutes = seconds / 60
  seconds -= minutes * 60
  "#{hours}h #{minutes}m #{seconds}s"
end

verts = graph.vertices.keys
done_pairs = []
estimate_remaining = -1

longest = verts.map.with_index do |start_vertex, idx|
  paths = nil
  rem = remaining(estimate_remaining)
  timings = Benchmark.measure do
    paths = verts.map.with_index do |end_vertex, eix|
      next if done_pairs.include?([start_vertex, end_vertex]) || done_pairs.include?([end_vertex, start_vertex])
      print "Processing vertex #{idx + 1} of #{verts.size}... (#{eix + 1}) (remaining: #{rem})"
      time, path = graph.shortest_path start_vertex, end_vertex
      lines = path.group_by { |v| v.split(' [') }.size
      clear_line
      done_pairs << [start_vertex, end_vertex]
      [time, path, lines]
    end
  end
  taken = timings.real.round
  estimate_remaining = taken * (verts.size - idx + 1)
  
  if idx + 1 == verts.size
    puts "Done."
  else
    clear_line
  end

  { time: paths.sort_by { |d| d[0] }[-1], path_length: paths.sort_by { |d| d[1] }[-1] }
end

longest_time = longest.sort_by { |d| d[:time] }[-1]
longest_path = longest.sort_by { |d| d[:path_length] }[-1]
most_lines = longest.sort_by { |d| d[:lines] }[-1]

puts "By time : #{longest_time[1][0]} to #{longest_time[1][-1]}"
puts "By stops: #{longest_path[1][0]} to #{longest_path[1][-1]}"
puts "By lines: #{most_lines[1][0]} to #{most_lines[1][-1]}"
