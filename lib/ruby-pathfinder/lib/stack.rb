class Stack
  def initialize
    @store = []
  end

  def add(data)
    @store << data
  end
  
  def pop
    @store.pop
  end

  def clear
    @store = []
  end

  def empty?
    @store.empty?
  end
end