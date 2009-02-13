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
      :dotted
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

class Input < Constant
  def style
    :dotted
  end
  
  def shape
    :ellipse
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


class MatLat
  def initialize(name, bind = nil, &proc)
    @name = name
    @env = bind || instance_eval(&proc)
  end
  
  def const(x)
    Constant.new(x)
  end

  def input(x)
    Input.new(x)
  end
  
  def dot
    Term.name_terms(@env)
    #puts Term.list_terms(@env).map {|t| t.long}
    graph = GraphvizR.new @name
    graph.rank :same, [:animatable, :superfast, :big]
    graph = Term.list_terms(@env).inject(graph) {|g, t|
      t.to_dot(g)
      g
    }

    #puts graph.to_dot
    graph.output(@name + '.dot', 'dot')
  end
end
