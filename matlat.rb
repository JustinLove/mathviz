class Term
  def self.name_terms(env)
    eval("local_variables", env).each do |var|
      value = eval(var, env)
      if value.respond_to? :name=
        value.name = var
      end
    end
  end
  
  def self.list_terms(env)
    eval("local_variables", env).map { |var|
      value = eval(var, env)
      if (value.kind_of?(Term))
        value
      else
        nil
      end
    }.compact
  end
  
  def self.binop(op)
    define_method(op) do |c|
      Equation.new(self, op, c)
    end
  end
  
  attr_accessor :name

  binop :+
  binop :-
  binop :*
  binop :/
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
    "(#{@name} = #{to_f})"
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
    n = @name && (@name + " = ")
    "(#{n}#{@a} #{@op} #{@b} = #{to_f})"
  end
  
  def to_i
    @a.to_i.__send__(@op, @b.to_i)
  end

  def to_f
    @a.to_f.__send__(@op, @b.to_f)
  end
end

def input(x)
  Constant.new(x)
end

scale = input 1.0
size = input 72
pi = input 3.14159
radians = pi * 2
count = input 60
unit = input 1
calcUnit = input 1000

relativeTime = count * unit * calcUnit
perimeter = size * scale * radians
pixel = input(1) / perimeter
tick = relativeTime * pixel

Term.name_terms(binding)
puts Term.list_terms(binding).map {|t| t.long}
