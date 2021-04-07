require_relative 'lib/graph'

graph = Graph.new

%w[A B C D E F G H].each do |vk|
  graph.add_vertex vk
end

graph.add_edge 'A', 'B', 2
graph.add_edge 'B', 'C', 1
graph.add_edge 'B', 'D', 2
graph.add_edge 'D', 'E', 1
graph.add_edge 'D', 'F', 4
graph.add_edge 'D', 'G', 1
graph.add_edge 'G', 'H', 1
graph.add_edge 'H', 'F', 1

distance, path = graph.shortest_path('A', 'F')
puts distance, path.inspect