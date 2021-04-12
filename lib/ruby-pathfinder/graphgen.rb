require 'csv'
require 'json'
require 'active_support/core_ext/string/inflections'
require_relative 'lib/graph'

DATA_PATH = File.join(__dir__, 'data/times.csv')
GRAPH_PATH = File.join(__dir__, 'data/graph.rbm')
STATION_PATH = File.join(__dir__, 'data/stations.json')
STATION_NAMES_PATH = File.join(__dir__, 'data/station_names.json')
INTERCHANGE_TIME = 210

data = CSV.parse(File.read(DATA_PATH, encoding: 'bom|utf-8'))
graph = Graph.new

# Start with the easy bit: add every station as a vertex, and every link as an edge between them.
data.each do |segment|
  line, from, to, time = segment
  next if line == 'ICG'
  from = "#{from} [#{line}]"
  to = "#{to} [#{line}]"

  graph.add_vertex from
  graph.add_vertex to
  graph.add_edge from, to, time.to_i
end

# Extract station names with lines from each item
station_names = data.map do |sg|
  sg[0] == 'ICG' ? nil : { sg[1] => "#{sg[1]} [#{sg[0]}]", sg[2] => "#{sg[2]} [#{sg[0]}]" }
end.compact

# Given an array of [a, b, c, d], returns each pair: [[a, b], [a, c], [a, d], [b, c], [b, d], [c, d]]
def combinations(ary)
  ary.map.with_index do |item, idx|
    next if idx == ary.size - 1
    ary[idx + 1...ary.size].map { |pair| [item, pair] }
  end.compact
end

# Map raw station names ("LIVERPOOL STREET") to every line variant ("LIVERPOOL STREET [HAM]")
# { "LIVERPOOL STREET" => ["LIVERPOOL STREET [HAM]", "LIVERPOOL STREET [CIR]", "LIVERPOOL STREET [CEN]"] }
all_stations = station_names.reduce({}) do |memo, station|
  station.each do |raw, lined|
    unless memo.include? raw
      memo[raw] = []
    end
    memo[raw] << lined
  end
  memo
end.map { |sn, lines| [sn, lines.uniq] }.to_h
interchanges = all_stations.select { |sn, lines| lines.size > 1 }

# Get every pair of same-station interchanges.
ic_edges = interchanges.values.map { |lines| combinations(lines) }.flatten.each_slice(2).to_a

# Get every pair of manually-specified interchanges (looking at you, Paddington)
ms_edges = data.select { |sg| sg[0] == 'ICG' }.map do |segment|
  line, from, to, time = segment
  from_variants = all_stations[from]
  to_variants = all_stations[to]
  from_variants.map do |from_lined|
    combinations([from_lined, *to_variants])
  end
end.flatten.each_slice(2).to_a

# Add all interchanges together and add them all as edges.
all_interchange_edges = (ic_edges + ms_edges).uniq
all_interchange_edges.each do |edge|
  lined, pair = edge
  graph.add_edge lined, pair, INTERCHANGE_TIME
end

station_names = JSON.load(File.read(STATION_NAMES_PATH))
stations_written = File.write(STATION_PATH,
                              JSON.dump(all_stations.keys.sort.map { |k| [k, station_names[k] || k.titleize] }.to_h))

written = File.write(GRAPH_PATH, Marshal.dump([graph, all_stations]))
puts "Saved station data. #{stations_written} bytes written, #{all_stations.size} stations."
puts "Saved graph. #{written} bytes written. " \
     "#{graph.vertices.size} vertices, " \
     "#{data.size + all_interchange_edges.size} edges, " \
     "#{all_stations.size} station variant sets."
