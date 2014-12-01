# here, we define a Stack class that simply delegates the equivalent "push", "pop",
# "to_s" and "clear" calls to the underlying Array object using the delegation
# methods provided by Ruby through the Forwardable class.  We could do the same
# thing using an Array, but that wouldn't let us restrict the methods that
# were supported by our Stack to just those methods that a stack should have

require 'forwardable'

class ProjectHanlon::Stack
  extend Forwardable
  def_delegators :@array, :push, :pop, :to_s, :clear, :count

  # initializes the underlying array for the stack
  def initialize
    @array = []
  end

  # peeks down to the n-th element in the stack (zero is the top,
  # if the 'n' value that is passed is deeper than the stack, it's
  # an error (and will result in an IndexError being thrown)
  def peek(n = 0)
    stack_idx = -(n+1)
    @array[stack_idx]
  end

  def size
    @array.size
  end

  def length
    @array.length
  end

  def include?(val)
    @array.include?(val)
  end

  def join(sep)
    @array.join(sep)
  end
end