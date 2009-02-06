class Equation
  def self.name_equations(bind)
    eval("local_variables", bind).each do |var|
      value = eval(var, bind)
      if value.respond_to? :name=
        value.name = var
      end
    end
  end
  
  attr_accessor :name

  def initialize(a, op, b)
    @a = a
    @op = op
    @b = b
  end

  def to_s
    @name || long
  end

  def long
    "(#{@a} #{@op} #{@b} = #{to_f})"
  end
  
  def to_i
    @a.to_i.__send__(@op, @b.to_i)
  end

  def to_f
    @a.to_f.__send__(@op, @b.to_f)
  end

  def *(c)
    Equation.new(self, :*, c)
  end
  
end

x = Equation.new(1, :+, 2)
y = x * 4
Equation.name_equations(binding)
puts y.long
