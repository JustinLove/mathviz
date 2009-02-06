class Equation
  def initialize(a, op, b)
    @a = a
    @op = op
    @b = b
  end
  
  def *(c)
    Equation.new(self, :*, c)
  end
  
  def to_i
    @a.to_i.__send__(@op, @b.to_i)
  end

  def to_f
    @a.to_f.__send__(@op, @b.to_f)
  end
  
  def to_s
    "(#{@a} #{@op} #{@b} = #{to_f})"
  end
end

puts Equation.new(1, :+, 2) * 4