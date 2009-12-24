require 'rubygems'
require 'graphviz_r'

# Something to return instead of dividing by zero, etc.
Infinity = 1.0/0

# Value objects that do the actual unit tracking.
# 
# Contains all the interesting power tracking and cancellation.
class Unit
  # The interal representation.  Current implementation method is hash-of-powers; e.g. {:m => 2, :s => -1} represents m*m/s
  attr_reader :unit

  # * With a symbol, creates a simple unit.
  # * With a hash-of-powers, it simply copies those values.
  # * Otherwise, it becomes a dimensionless unit.
  def initialize(h = nil)
    @unit = Hash.new(0)
    case h
    when Hash; @unit.merge!(h); normalize!
    when Symbol: @unit[h] = 1
    end
    @unit.freeze
    freeze
  end

  # Implement a simple binary operation.  It verifies that the units match and returns the unit ERROR if not.
  def binop(other)
    if (unit != other.unit)
      #p "#{to_s} !+- #{other.to_s}"
      return Unit.new(:ERROR)
    end
    return self
  end

  alias_method :+, :binop
  alias_method :-, :binop
  alias_method :<, :binop
  alias_method :>, :binop
  alias_method :==, :binop
  alias_method :max, :binop
  alias_method :min, :binop
  alias_method :&, :binop
  alias_method :|, :binop

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

  def to_s
    n = stream(numerator)
    d = stream(denominator)
    return '' unless (n || d)
    return "#{n||1}/#{d}" if d
    return n
  end

  private

  # Produce a string of multiplied terms
  def stream(units)
    x = units.map {|u,power| [u] * power.abs }.flatten.join('*')
    if (x.empty?)
      return nil
    else
      x
    end
  end

  # Remove zero-powers
  def normalize!
    unit.reject! { |u,power| power == 0 }
    self
  end
end

# Common container for defined units.
#
# including Units triggers extension by Units::Class.  Units includes Units::Class itself, so all those methods are available.
module Units
  # Provides the new_units class method to all classes with units
  module Class
    # Define new units (instance methods) on module Units (where they will be picked up by everything including the module)
    # Defined methods are essentialy aliases for #unit(name); see Measurable / Measured
    def new_units(*units)
      units.each do |u|
        Units.__send__ :define_method, u do
          unit(u)
        end
      end
    end

    # extend Units::Class
    def included(host)
      host.extend(Units::Class)
    end
  end

  extend Units::Class
end

# Something (i.e. Numeric) which does not have Units, but can be turned into something which does (i.e., Constant)
module Measurable
  include Units

  # return constant wrapping self with the specified units; see also Units::Class#new_units
  def unit(x)
    Constant.new(self).unit(x)
  end

  # return constant wrapping self with new units assigned to the denominator
  def per
    Constant.new(self).per
  end
end

# Something (i.e. Term) which has Units.
module Measured
  include Units

  # Return a string representation of the units portion, with space if applicable
  def with_units
    u = units.to_s
    if (u.empty?)
      u
    else
      ' ' + u
    end
  end

  # Add the named unit to our units and return self.  See also Units::Class#new_units
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

  # Statefull toggle numerator/denominator of unit assignment; e.g. m/s = .m.per.s
  def per
    @unit_sign ||= 1
    @unit_sign *= -1
    self
  end

  # attr_reader
  def units
    @unit || Unit.new
  end
end

class Numeric
  include Measurable

  # Provide in operator form
  def max(b)
    [self, b].max
  end

  # Provide in operator form
  def min(b)
    [self, b].min
  end

  # Dummy defintion for all numerics.  Normally only defined on things where it can possible return false.
  def finite?
    true
  end
end

class Object
  # Representation used for graphviz node names
  def node
    to_s
  end
end

# Base class for graphable objects.  It also contain the operators, which return Operation subclasses.
class Term
  include Measured

  # Assign names to named Terms, so the name can be effiently looked up from the Term object.
  def self.name_terms!(env)
    eval("local_variables", env).each do |var|
      value = eval(var, env)
      if value.respond_to? :name=
        value.name = var
      end
    end
  end

  # Return a list of all Terms accessible from a binding
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

  # Define op as a binary operator
  def self.binop(op)
    define_method(op) do |c|
      Operation::Binary.new(self, op, c)
    end
  end

  # Define op as an unary operator
  def self.unop(op)
    define_method(op) do
      Operation::Unary.new(self, op)
    end
  end

  # Graphviz node name; see Term#name_terms!
  attr_accessor :name

  def to_s
    @name || anon
  end

  # A string representation of the node's data, typically calculated value with units.
  def data
    f = to_f
    if (f.kind_of?(TrueClass) || f.kind_of?(FalseClass))
      f.to_s
    elsif (!f.respond_to? :finite?)
      f.to_s + with_units
    elsif (!f.finite?)
      Infinity.to_s
    elsif (f.floor == f)
      f.to_i.to_s + with_units
    else
      f.to_s + with_units
    end
  end

  def to_i
    f = to_f
    return Infinity unless f.finite?
    f.to_i
  end

  # Text label for graph nodes
  def label
    if (@name)
      [data, node].join("\n")
    else
      data
    end
  end

  # Graphviz node shape
  def shape
    :ellipse
  end

  # Graphviz node color
  def color
    :black
  end

  # Graphviz node line style
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

  private
  @@anon_master = 'A'

  # Produces an unique name for #anonymous? nodes.  Results are memoized for each instance.
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

  public

  ##
  unop :floor

  ##
  unop :ceil


  ##
  binop :+

  ##
  binop :-

  ##
  binop :*

  ##
  binop :/

  ##
  binop :max

  ##
  binop :min

  ##
  binop :>

  ##
  binop :<

  ##
  binop :<=

  ##
  binop :>=

  ##
  binop :&

  ##
  binop :|

  ##
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


class MathViz
  VERSION = '1.0.0'

  def initialize(name = nil, bind = nil, &proc)
    @name = name || File.basename($PROGRAM_NAME, '.rb')
    @env = bind || instance_eval(&proc)
  end

  def const(x)
    Constant.new(x)
  end

  def input(x)
    Input.new(x)
  end

  def dot
    Term.name_terms!(@env)
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
