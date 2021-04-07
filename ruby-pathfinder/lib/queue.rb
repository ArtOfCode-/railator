class Queue
  def initialize
    @store = []
  end

  def enqueue(data)
    @store << data
  end

  def dequeue
    @store.shift
  end

  def clear
    @store = []
  end

  def empty?
    @store.empty?
  end

  alias :nq :enqueue
  alias :dq :dequeue
end
