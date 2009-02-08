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
  
  def style
    :solid
  end
  
  def to_dot(g)
    g[node] [:label => [node, data].join("\n"), :shape => shape, :color => color, :style => style]
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
  binop :<
  binop :<=
  binop :>=
  binop :&
  binop :|
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
  
  def style
    if @name
      :solid
    else
      :dotted
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
second = input 1000

scale = input 1.0
size = input 72
count = input 10
unit = input 1
calcUnit = input 10
timeMultiplier = input 1
time = input((Time.now.to_f * 1000).floor)

root_position = time / calcUnit
unit_position = root_position / unit
un_position = unit_position / count

resolution = unit * count
relativeTime = calcUnit * resolution
diameter = size * scale
perimeter = diameter * radians
pixel = input(1) / perimeter
tick = relativeTime * pixel
realTime = calcUnit.min(tick.max(1000))
delay = realTime / timeMultiplier
threashold = realTime * 2

frameRate = input 10
step = second / frameRate
passed = step * timeMultiplier
#passed = delay * timeMultiplier
ms = time + passed

root_to = ms / calcUnit
unit_to = root_to / unit
un_to = unit_to / count

delta = un_to - un_position
timeDelta = relativeTime * delta
big = timeDelta > threashold
visible = delta > pixel
not_fast = delay >= 1000
jump = big & not_fast
superfast = delay < 1


Term.name_terms(binding)
#puts Term.list_terms(binding).map {|t| t.long}
graph = GraphvizR.new 'dc'
graph.rank :same, [:pixel, :delta]
#graph.rank :same, [:tick, :timeDelta, :threashold]
graph = Term.list_terms(binding).inject(graph) {|g, t|
  t.to_dot(g)
  g
}

#puts graph.to_dot
graph.output('dc.dot', 'dot')
