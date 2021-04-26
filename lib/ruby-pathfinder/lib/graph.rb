require_relative 'queue'
require_relative 'stack'

class Graph
  class Vertex
    attr_accessor :key, :edges

    def initialize(key)
      self.key = key
      self.edges = {}
    end

    def to_s
      self.key.to_s
    end
  end

  attr_accessor :vertices

  def initialize
    @vertices = {}
  end

  def add_vertex(key)
    return if @vertices.include? key

    @vertices[key] = Vertex.new(key)
  end


  def remove_vertex(key)
    @vertices.delete key
    @vertices.each do |v|
      v.edges.delete key
    end
  end

  def add_edge(k1, k2, weight)
    @vertices[k1].edges[k2] = weight
    @vertices[k2].edges[k1] = weight
  end

  def remove_edge(k1, k2)
    @vertices[k1].edges.delete k2
    @vertices[k2].edges.delete k1
  end

  def breadth_first(start, target: nil)
    q = Queue.new
    q.nq @vertices[start]
    discovered = { start => true }
    result = []
    until q.empty?
      vertex = q.dq
      if block_given?
        yield vertex.key
      end
      result << vertex.key
      if !target.nil? && vertex.key == target
        return result
      end
      vertex.edges.keys.each do |eq|
        next if discovered.include? eq
        q.nq @vertices[eq]
        discovered[eq] = true
      end
    end
    result
  end

  def depth_first(start, target: nil)
    s = Stack.new
    s.add @vertices[start]
    discovered = { start => true }
    result = []
    until s.empty?
      vertex = s.pop
      if block_given?
        yield vertex.key
      end
      result << vertex.key
      if !target.nil? && vertex.key == target
        return result
      end
      vertex.edges.keys.reverse.each do |eq, ew|
        next if discovered.include? eq
        s.add @vertices[eq]
        discovered[eq] = true
      end
    end
    result
  end

  def shortest_path(start, target)
    verts = []
    distances = {}
    previous = {}

    @vertices.each do |key, vert|
      verts << key
      distances[key] = Float::INFINITY
      previous[key] = nil
    end

    distances[start] = 0

    until verts.empty?
      current = extract_min(verts.map { |k| [k, distances[k]] }.to_h)
      verts.delete current

      if current.nil?
        raise ArgumentError, "No path exists between #{start} and #{target}"
      end

      if current == target
        return [distances[current], prev_sequence(current, previous)]
      end

      @vertices[current].edges.each do |nb, nb_dist|
        next unless verts.include? nb
        alt = distances[current] + nb_dist
        if alt < distances[nb]
          distances[nb] = alt
          previous[nb] = current
        end
      end
    end
  end

  private

  def extract_min(hsh)
    least = Float::INFINITY
    key = nil
    hsh.each do |k, v|
      if v < least
        key = k
        least = v
      end
    end
    key
  end

  def prev_sequence(from, prevs)
    sequence = [from]
    until prevs[from].nil?
      sequence << prevs[from]
      from = prevs[from]
    end
    sequence.reverse
  end
end
