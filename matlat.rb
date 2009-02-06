class Term
  def self.name_terms(bind)
    eval("local_variables", bind).each do |var|
      value = eval(var, bind)
      if value.respond_to? :name=
        value.name = var
      end
    end
  end
  
  attr_accessor :name
  
  def *(c)
    Equation.new(self, :*, c)
  end

  def +(c)
    Equation.new(self, :+, c)
  end
end

class Constant < Term
  def initialize(a)
    super()
    @a = a
  end

  def to_s
    @name || long
  end

  def long
    "#{to_f}"
  end
  
  def to_i
    @a.to_i
  end

  def to_f
    @a.to_f
  end
end

class Equation < Term
  def initialize(a, op, b)
    super()
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
end

u = Constant.new(1)
v = Constant.new(2)
x = u + v
y = x * 4
Term.name_terms(binding)
puts x.long
puts y.long
