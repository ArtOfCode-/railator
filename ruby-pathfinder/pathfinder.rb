require_relative 'lib/graph'
require 'set'
require 'benchmark'

hours, minutes, seconds, path_stripped_through = nil

extime = Benchmark.measure do
  GRAPH_PATH = 'data/graph.rbm'
  graph, station_variants = Marshal.load(File.read(GRAPH_PATH))

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

  hours = time / 3600
  time -= hours * 3600
  minutes = time / 60
  time -= minutes * 60
  seconds = time

  path_lines = path.group_by { |stn| stn.split(' [')[1] }
  path_stripped_through = path_lines.map { |ln, pg| [pg[0], pg[-1]] }.flatten
end

puts "Travel time: #{hours}h #{minutes}m #{seconds}s"
puts "Path: #{path_stripped_through.join(' -> ')}"
puts "Execution time: #{(extime.real * 1000).round}ms"
