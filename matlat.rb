require 'rubygems'
require 'graphviz_r'

Infinity = 1.0/0

class Unit
  attr_reader :unit

  def initialize(h = nil)
    @unit = Hash.new(0)
    case h
    when Hash; @unit.merge!(h); normalize!
    when Symbol: @unit[h] = 1
    end
    @unit.freeze
    freeze
  end

  def normalize!
    unit.reject! { |u,power| power == 0 }
    self
  end

  def +(other)
    if (unit != other.unit)
      p "#{to_s} !+- #{other.to_s}"
      return Unit.new(:ERROR)
    end
    return self
  end
  alias_method :-, :+

  def *(other)
    x = @unit.dup
    other.unit.each do |u,power|
      x[u] += power
    end
    Unit.new(x)
  end

  def /(other)
    x = @unit.dup
    other.unit.each do |u,power|
      x[u] -= power
    end
    Unit.new(x)
  end

  def numerator
    unit.reject {|u,power| power < 0}
  end

  def denominator
    unit.reject {|u,power| power > 0}
  end

  def stream(units)
    x = units.map {|u,power| [u] * power.abs }.flatten.join('*')
    if (x.empty?)
      return nil
    else
      x
    end
  end

  def to_s
    n = stream(numerator)
    d = stream(denominator)
    return '' unless (n || d)
    return "#{n||1}/#{d}" if d
    return n
  end
end

module Units
  module Class
    def new_units(*units)
      units.each do |u|
        Units.__send__ :define_method, u do
          unit(u)
        end
      end
    end

    def included(host)
      host.extend(Units::Class)
    end
  end

  extend Units::Class
end

module Measurable
  include Units

  def to_s_with_units
    to_s
  end

  def unit(x)
    Constant.new(self).unit(x)
  end

  def per
    Constant.new(self).per
  end
end

module Measured
  include Units

  def with_units
    u = units.to_s
    if (u.empty?)
      u
    else
      ' ' + u
    end
  end

  def to_s_with_units
    to_s + with_units
  end

  def unit(x)
    @unit ||= Unit.new
    @unit_sign ||= 1
    if (@unit_sign > 0)
      @unit *= Unit.new(x)
    else
      @unit /= Unit.new(x)
    end
    self
  end

  def per
    @unit_sign ||= 1
    @unit_sign *= -1
    self
  end

  def units
    @unit || Unit.new
  end
end

class Numeric
  include Measurable

  def max(b)
    [self, b].max
  end

  def min(b)
    [self, b].min
  end

  def finite?
    true
  end
end

class Object
  def node
    to_s
  end
end

class Term
  include Measured

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
      Operation::Binary.new(self, op, c)
    end
  end

  def self.unop(op)
    define_method(op) do
      Operation::Unary.new(self, op)
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
    i,f = to_i,to_f
    return "Infinity" unless f.finite?
    if (f.floor == f)
      i.to_s + with_units
    else
      f.to_s + with_units
    end
  end

  def label
    if (@name)
      [data, node].join("\n")
    else
      data
    end
  end

  def shape
    :ellipse
  end
  
  def color
    :black
  end

  def style
    if anonymous?
      :dotted
    elsif constant?
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

  def anonymous?
    !@name
  end

  unop :floor

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
    return Infinity unless @a.finite?
    @a.to_i
  end

  def to_f
    @a.to_f
  end

  def units
    if @a.respond_to? :units
      @a.units
    else
      super
    end
  end

  def shape
    :plaintext
  end
  
  def constant?
    true
  end

  def finite?
    @a.finite?
  end
end

class Input < Constant
  def shape
    :ellipse
  end

  def constant?
    false
  end
end

class Operation < Term
  def term(x)
    if (x.kind_of?(Term))
      x
    else
      Constant.new(x)
    end
  end

  def shape
    :box
  end

  def color
    :red
  end
end

class Operation::Unary < Operation
  def initialize(a, op)
    super()
    @a = term(a)
    @op = op
  end

  def long
    n = @name && (@name + " = ")
    "(#{n}#{@a} #{@op} = #{to_f})"
  end

  def to_dot(g)
    super
    (g[@a.node] >> g[node]) [:arrowhead => :normal, :headlabel => @op.to_s, :labeldistance => '2']
    @a.to_dot(g) if (@a.respond_to?(:name) && @a.name.nil?)
  end

  def to_i
    return Infinity unless @a.to_i.finite?
    @a.to_i.__send__(@op)
  end

  def to_f
    return Infinity unless @a.to_f.finite?
    @a.to_f.__send__(@op)
  end

  def units
    @a.units
  end

  def constant?
    @a.constant?
  end
end

class Operation::Binary < Operation
  def initialize(a, op, b)
    super()
    @a = term(a)
    @op = op
    @b = term(b)
  end

  def long
    n = @name && (@name + " = ")
    "(#{n}#{@a} #{@op} #{@b} = #{to_f})"
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
    (g[@a.node] >> g[node]) [:arrowhead => :normal, :headlabel => @op.to_s, :labeldistance => '2']
    (g[@b.node] >> g[node]) [:arrowhead => :onormal]
    @a.to_dot(g) if (@a.respond_to?(:name) && @a.name.nil?)
    @b.to_dot(g) if (@b.respond_to?(:name) && @b.name.nil?)
  end

  def to_i
    f = to_f
    return Infinity unless f.finite?
    f.to_i
  end

  def to_f
    @a.to_f.__send__(@op, @b.to_f)
  end

  def units
    @a.units.__send__(@op, @b.units)
  end

  def constant?
    @a.constant? && @b.constant?
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
    graph = Term.list_terms(@env).inject(graph) {|g, t|
      t.to_dot(g)
      g
    }

    #puts graph.to_dot
    graph.output(@name + '.dot', 'dot')
  end
end
