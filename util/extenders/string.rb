class String
  def to_class
    Kernel.const_get self
  rescue NameError
    nil
  end

  def is_a_defined_class?
    puts "its a class" if self.to_class
    true if self.to_class
  rescue NameError
    puts "nope"
    false
  end
end