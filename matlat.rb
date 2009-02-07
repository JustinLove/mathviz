require 'graphviz_r'

class Numeric
  def max(b)
    [self, b].max
  end
  
  def min(b)
    [self, b].min
  end
end

class Object
  def node
    to_s
  end
end

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
  
  def data
    to_f
  end
  
  def label
    [node, data].join("\n")
  end              
  
  def shape
    :ellipse
  end
  
  def color
    :black
  end
  
  def to_dot(g)
    g[node] [:label => [node, data].join("\n"), :shape => shape, :color => color]
  end
  
  @@anon_master = 'a'
  def anon
    if (@anon)
      @anon
    else
      @anon = @@anon_master
      @@anon_master = @@anon_master.succ
      #puts "#{self.object_id} anon #{@anon}"
      @anon
    end
  end

  binop :+
  binop :-
  binop :*
  binop :/
  binop :max
  binop :min
  binop :>
end

class Constant < Term
  def initialize(a)
    super()
    @a = a
  end

  def to_s
    @name || to_f.to_s
  end

  def long
    n = @name && (@name + " = ")
    "(#{n}#{to_f})"
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
    @name || anon
  end
  
  def long
    n = @name && (@name + " = ")
    "(#{n}#{@a} #{@op} #{@b} = #{to_f})"
  end
  
  def data
    "#{@op} = #{to_f}"
  end
  
  def shape
    return :box
  end
  
  def color
    case @op
    when :+: :green;
    when :-: :yellow;
    when :*: :blue;
    when :/: :cyan;
    else :red;
    end
  end
  
  def to_dot(g)
    super
    g[@a.node] >> g[node]
    g[@b.node] >> g[node]
    @a.to_dot(g) if (@a.respond_to?(:name) && @a.name.nil?)
    @b.to_dot(g) if (@b.respond_to?(:name) && @b.name.nil?)
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

pi = input 3.14159
radians = pi * 2

scale = input 1.0
size = input 72
count = input 60
unit = input 1
calcUnit = input 1000
timeMultiplier = input 1
time = input Time.now
ms = time + 500

root_position = time / calcUnit
unit_position = root_position / unit
un_position = unit_position / count

root_to = ms / calcUnit
unit_to = root_to / unit
un_to = unit_to / count

relativeTime = count * unit * calcUnit
diameter = size * scale
perimeter = diameter * radians
pixel = input(1) / perimeter
tick = relativeTime * pixel
realTime = calcUnit.min(tick.max(1000))
delay = realTime / timeMultiplier
threashold = delay * 2
delta = un_to - un_position
timeDelta = relativeTime * delta
jump = timeDelta > threashold


Term.name_terms(binding)
#puts Term.list_terms(binding).map {|t| t.long}
puts Term.list_terms(binding).inject(GraphvizR.new 'dc') {|g, t|
  t.to_dot(g)
  g
}.to_dot
