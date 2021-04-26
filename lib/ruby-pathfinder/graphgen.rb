require 'csv'
require 'json'
require_relative 'lib/graph'

TIMES_PATH = File.join(__dir__, 'data/Times.csv')
GRAPH_PATH = File.join(__dir__, 'data/graph.rbm')
STATION_PATH = File.join(__dir__, 'data/stations.json')
LINE_DEFS_PATH = File.join(__dir__, 'data/LineDefs.csv')
LINES_PATH = File.join(__dir__, 'data/lines.json')
EDGES_CSV_PATH = File.join(__dir__, 'data/edges.csv')
INTERCHANGE_TIME = 210

times_data = CSV.parse(File.read(TIMES_PATH, encoding: 'bom|utf-8'))
times_data.shift
graph = Graph.new

all_stations = {}
all_stations_codes = {}
atco_name_map = {}

times_data.each do |segment|
  _, _, line, origin, origin_atco, dest, dest_atco, link_time, _, _ = segment
  next if line == 'ICG'

  # Set ATCO flags to G, because that's what TfL systems seems to use for some dumb reason.
  origin_atco[3] = 'G'
  dest_atco[3] = 'G'

  from = "#{origin_atco} [#{line}]"
  to = "#{dest_atco} [#{line}]"
  
  # Add this variant of origin and destination to the list of all stations under their parent stations.
  all_stations[origin] ||= []
  all_stations[dest] ||= []
  all_stations[origin] << from unless all_stations[origin].include? from
  all_stations[dest] << to unless all_stations[dest].include? to

  # Likewise, but add them to another map under their ATCO codes.
  all_stations_codes[origin_atco] ||= []
  all_stations_codes[dest_atco] ||= []
  all_stations_codes[origin_atco] << from unless all_stations_codes[origin_atco].include? from
  all_stations_codes[dest_atco] << to unless all_stations_codes[dest_atco].include? to

  # Map origin and destination ATCO codes to real names.
  atco_name_map[origin_atco] = origin
  atco_name_map[dest_atco] = dest

  # Actually add these station variants to the graph and create a reciprocal edge between them.
  graph.add_vertex from
  graph.add_vertex to
  graph.add_edge from, to, link_time.to_i
end

# Given an array of [a, b, c, d], returns each pair: [[a, b], [a, c], [a, d], [b, c], [b, d], [c, d]]
def combinations(ary)
  ary.map.with_index do |item, idx|
    next if idx == ary.size - 1
    ary[idx + 1...ary.size].map { |pair| [item, pair] }
  end.compact
end

# List only those stations that have more than one line passing through them as an interchange.
interchanges = all_stations.select { |sn, lines| lines.size > 1 }

# Get every pair of same-station interchanges.
ic_edges = interchanges.values.map { |lines| combinations(lines) }.flatten.each_slice(2).to_a

# Get every pair of manually-specified interchanges.
ms_edges = times_data.select { |sg| sg[2] == 'ICG' }.map do |segment|
  _, _, line, origin, origin_atco, dest, dest_atco, link_time, _, _ = segment
  from_variants = all_stations[origin]
  to_variants = all_stations[dest]
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

# Dump line definitions to JSON.
line_defs = CSV.parse(File.read(LINE_DEFS_PATH, encoding: 'bom|utf-8'))
line_defs.shift
line_defs_written = File.write(LINES_PATH, JSON.dump(line_defs.to_h))

# Dump out ATCO <-> station name map.
stations_written = File.write(STATION_PATH, JSON.dump(atco_name_map))

# Finally, dump the graph itself and the list of station name variants in Ruby marshal form.
graph_written = File.write(GRAPH_PATH, Marshal.dump([graph, all_stations_codes]))

puts "Saved line definitions. #{line_defs_written} bytes written, #{line_defs.size} lines."
puts "Saved station data. #{stations_written} bytes written, #{all_stations.size} stations."
puts "Saved graph. #{graph_written} bytes written. " \
     "#{graph.vertices.size} vertices, " \
     "#{graph.vertices.map { |n, v| v.edges.size }.sum} edges, " \
     "#{all_stations.size} station variant sets."
