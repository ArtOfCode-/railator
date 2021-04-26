# Run graphgen.rb first to generate an up to date copy of the station graph before running these tests against it.

require 'json'
require 'colorize'
require_relative 'lib/graph'

GRAPH_PATH = File.join(__dir__, 'data/graph.rbm')
STATION_PATH = File.join(__dir__, 'data/stations.json')

graph, station_variants = Marshal.load(File.read(GRAPH_PATH))
station_map = JSON.parse(File.read(STATION_PATH))
names_atco = station_map.values.zip(station_map.keys).to_h

def combinations(ary)
  ary.map.with_index do |item, idx|
    next if idx == ary.size - 1
    ary[idx + 1...ary.size].map { |pair| [item, pair] }
  end.compact
end

def print_line(text)
  width = `stty size`.strip.split.map(&:to_i)[1]
  print "\r" + " " * width + "\r" + text
end

# Line continuity test definitions. Ensure every line has a valid path from start to end.
line_continuity = {
  'VIC' => ['940GZZLUBXN', '940GZZLUWWL'],
  'PIC' => ['940GZZLUCKS', '940GZZLUUXB', '940GZZLUHR4', '940GZZLUHR5'],
  'WTC' => ['940GZZLUWLO', '940GZZLUBNK'],
  'NTH' => ['940GZZLUEGW', '940GZZLUHBT', '940GZZLUMHL', '940GZZLUGDG', '940GZZLUODS', '940GZZLUMDN'],
  'MET' => ['940GZZLUCSM', '940GZZLUAMS', '940GZZLUWAF', '940GZZLUUXB', '940GZZLUALD'],
  'JUB' => ['940GZZLUSTM', '940GZZLUSTD'],
  'DIS' => ['940GZZLUEBY', '940GZZLURMD', '940GZZLUKOY', '940GZZLUWIM', '940GZZLUERC',
  '940GZZLUUPM'],
  'CIR' => ['940GZZLUALD', '940GZZLUHSC', '940GZZLUSKS', '940GZZLUPAC'],
  'HAM' => ['940GZZLUHSC', '940GZZLUBKG'],
  'CEN' => ['940GZZLUWRP', '940GZZLUEBY', '940GZZLUCWL', '940GZZLUEPG', '940GZZLUSWF', '940GZZLURBG'],
  'BAK' => ['940GZZLUEAC', '940GZZLUHAW'],
  'OVG-WEU' => ['910GWATFJDC', '910GEUSTON'],
  'OVG-GOB' => ['910GGOSPLOK', '910GBARKING'],
  'OVG-LST' => ['910GCHESHNT', '910GENFLDTN', '910GCHINGFD', '910GLIVST'],
  'OVG-HSL' => ['910GCLPHMJW', '910GNWCROSS', '910GCRYSTLP', '910GWCROYDN', '910GHIGHBYA', '910GSURREYQ'],
  'OVG-SRC' => ['910GSTFD', '910GWLSDJHL', '910GCLPHMJW', '910GRICHMND'],
  'OVG-ROM' => ['910GROMFORD', '910GUPMNSTR'],
  'ELZ-E' => ['910GSHENFLD', '910GLIVST'],
  'ELZ-W' => ['910GPADTON', '910GHTRWTM4', '910GHTRWTM5'],
  'DLR' => ['940GZZDLBNK', '940GZZDLTWG', '940GZZDLDEV', '940GZZDLLEW', '940GZZDLWLA', '940GZZDLBEC', '940GZZDLSTL', '940GZZDLSIT'],
  'TRM' => ['940GZZCRNWA', '940GZZCRBEK', '940GZZCRELM', '940GZZCRWMB', '940GZZCRRVC', '940GZZCRCTR', '940GZZCRCEN'],
  'XGN' => ['910GMGTE', '910GPALMRSG']
}

lc_tests = line_continuity.map do |line, endpoints|
  [line, combinations(endpoints).flatten.each_slice(2).to_a]
end.to_h

total_lc_tests = lc_tests.values.map(&:size).sum
lc_tests_run = 0

lc_tests.each do |line, combinations|
  combinations.each do |combo|
    origin, dest = combo
    begin
      graph.shortest_path "#{origin} [#{line}]", "#{dest} [#{line}]"
      lc_tests_run += 1
      print_line "#{"#{lc_tests_run}/#{total_lc_tests}".green} continuity tests run successfully..."
    rescue ArgumentError => ex
      puts
      puts "#{"Test failed".red} (#{line} #{origin} <-> #{dest}): #{ex.message}"
    end
  end
end

if lc_tests_run < total_lc_tests
  puts
  puts "#{lc_tests_run}/#{total_lc_tests} line continuity tests successful."
else
  puts
end

# Interchange test definitions.
interchanges = [
  ['940GZZLUHRC [PIC]', '910GHTRWAPT [ELZ-W]'],
  ['910GWLSDJHL [OVG-WEU]', '940GZZLUWJN [BAK]'],
  ['940GZZLUODS [NTH]', '910GOLDST [XGN]'],
  ['940GZZCRWMB [TRM]', '940GZZLUWIM [DIS]'],
  ['940GZZCRWCR [TRM]', '910GWCROYDN [OVG-HSL]'],
  ['910GSTFD [ELZ-E]', '940GZZDLSTD [DLR]'],
  ['910GSTFD [OVG-SRC]', '940GZZLUSTD [CEN]'],
  ['940GZZDLSTD [DLR]', '940GZZLUSTD [CEN]'],
  ['910GSTFD [ELZ-E]', '910GSTFD [OVG-SRC]'],
  ['910GLIVST [OVG-LST]', '940GZZLULVT [CEN]'],
  ['910GEUSTON [OVG-WEU]', '940GZZLUEUS [VIC]'],
  ['910GPADTON [ELZ-W]', '940GZZLUPAC [CIR]'],
  ['940GZZLUTWH [DIS]', '940GZZDLTWG [DLR]'],
  ['910GHAKNYNM [OVG-LST]', '910GHACKNYC [OVG-SRC]']
]

ic_tests_run = 0
interchanges.each do |ic|
  origin, dest = ic
  begin
    graph.shortest_path origin, dest
    ic_tests_run += 1
    print_line "#{"#{ic_tests_run}/#{interchanges.size}".green} interchange tests run successfully..."
  rescue ArgumentError => ex
    puts
    puts "#{"Test failed".red} (#{origin} <-> #{dest}): #{ex.message}"
  end
end

if ic_tests_run < interchanges.size
  puts
  puts "#{ic_tests_run}/#{interchanges.size} interchange tests successful."
else
  puts
end
