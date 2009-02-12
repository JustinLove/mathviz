require 'rubygems'
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
  
  def to_s
    @name || anon
  end
  
  def node
    to_s
  end
  
  def data
    if (to_f.floor == to_f)
      to_i
    else
      to_f
    end
  end
  
  def label
    if (@name)
      [node, data].join("\n")
    else
      data.to_s
    end
  end              
  
  def shape
    :ellipse
  end
  
  def color
    :black
  end
  
  def style
    if @name
      :solid
    else
      :dashed
    end
  end
  
  def to_dot(g)
    g[node] [:label => label, :shape => shape, :color => color, :style => style]
  end
  
  @@anon_master = 'A'
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
  binop :==
end

class Constant < Term
  def initialize(a)
    super()
    @a = a
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
  
  def shape
    :plaintext
  end
end

class Equation < Term
  def initialize(a, op, b)
    super()
    @a = term(a)
    @op = op
    @b = term(b)
  end
  
  def term(x)
    if (x.kind_of?(Term))
      x
    else
      Constant.new(x)
    end
  end

  def long
    n = @name && (@name + " = ")
    "(#{n}#{@a} #{@op} #{@b} = #{to_f})"
  end
  
  def data
    "#{@op} #{to_f}"
  end
  
  def shape
    if ([:>, :<, :>=, :<=, :&, :|, :==].include? @op)
      :ellipse
    else
      :box
    end
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
    (g[@a.node] >> g[node]) [:arrowhead => :normal]
    (g[@b.node] >> g[node]) [:arrowhead => :onormal]
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
second = input 1000

scale = input 1.0
diameter = input 172
count = input 10
unit = input 1
resolution = input 100
timeMultiplier = input 1
time = input((Time.now.to_f * 1000).floor)

root_position = time / resolution
unit_position = root_position / unit
un_position = unit_position / count

timels = unit * count
ms_rev = resolution * timels
rev_s = input(1000) / ms_rev
real_rev_s = rev_s * timeMultiplier
rev_timel = input(1) / timels
perimeter = diameter * pi
rev_pixel = scale / perimeter
tick = rev_timel.min(rev_pixel.max(rev_s))
threshold = tick * 2
ms_tick = ms_rev * tick
delay = ms_tick / timeMultiplier

frameRate = input 10
step = second / frameRate
passed = step * timeMultiplier
#passed = delay * timeMultiplier
ms = time + passed

root_to = ms / resolution
unit_to = root_to / unit
un_to = unit_to / count

delta = un_to - un_position
big = delta > threshold
visible = delta > rev_pixel
animatable = real_rev_s < 0.1
jump = big & animatable
superfast = real_rev_s > 2


Term.name_terms(binding)
#puts Term.list_terms(binding).map {|t| t.long}
graph = GraphvizR.new 'dc'
graph.rank :same, [:animatable, :superfast, :big]
graph = Term.list_terms(binding).inject(graph) {|g, t|
  t.to_dot(g)
  g
}

#puts graph.to_dot
graph.output('dc.dot', 'dot')
