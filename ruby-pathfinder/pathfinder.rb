require_relative 'lib/graph'
require 'set'
require 'benchmark'
require 'json'

time_full, hours, minutes, seconds, path, path_stripped_through, path_data = nil

extime = Benchmark.measure do
  GRAPH_PATH = 'data/graph.rbm'
  LINES_PATH = 'data/lines.json'
  graph, station_variants = Marshal.load(File.read(GRAPH_PATH))
  line_data = JSON.load(File.read(LINES_PATH))

  splat = ARGV.join(' ').split(' -- ')
  if splat.size < 2
    STDERR.puts "Not enough parameters. Usage:\nruby pathfinder.rb ORIGIN -- DESTINATION"
    exit 10
  end

  from = splat[0]
  to = splat[1]

  from_variants = station_variants[from]
  to_variants = station_variants[to]

  paths = from_variants.map do |from_lined|
    to_variants.map do |to_lined|
      tr, pr = graph.shortest_path(from_lined, to_lined)
      [tr, Set.new(pr)]
    end
  end.flatten.each_slice(2).to_a.sort_by { |path| path[0] }

  time, path = paths[0]
  path = path.to_a
  time_full = time

  hours = time / 3600
  time -= hours * 3600
  minutes = time / 60
  time -= minutes * 60
  seconds = time

  path_lines = path.group_by { |stn| stn.split(' [')[1] }
  path_stripped_through = path_lines.map { |ln, pg| [pg[0], pg[-1]] }.flatten
  with_lines = path_stripped_through.map do |lined|
    station, line = lined.split(' [')
    line = line.gsub(']', '')
    { name: station, line: line_data[line] }
  end
  uniq_lines = with_lines.map { |l| l[:line] }.uniq
  grouped = with_lines.group_by { |l| l[:line] }
  path_data = uniq_lines.map { |l| { line: l, from: grouped[l][0][:name], to: grouped[l][-1][:name] } }
                        .filter { |d| d[:from] != d[:to] }
end

puts JSON.dump({ time: { total: time_full, hours: hours, minutes: minutes, seconds: seconds },
                 time_human: "#{hours}h #{minutes}m #{seconds}s", path: path,
                 steps: path_data, execution_time: (extime.real * 1000).round })
