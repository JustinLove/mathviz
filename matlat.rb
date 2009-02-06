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
    @name || long
  end

  def long
    "(#{@a} #{@op} #{@b} = #{to_f})"
  end
  
  attr_accessor :name
end

x = Equation.new(1, :+, 2)
y = x * 4
local_variables.each do |var|
  value = eval(var)
  if value.respond_to? :name=
    value.name = var
  end
end

puts y.long
