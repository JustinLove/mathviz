require 'graphviz_r'

# Top level object.
class MathViz
  # RubyGem version
  VERSION = '1.1.0'

  # Something to return instead of dividing by zero, etc.
  Infinity = 1.0/0

  # * base name of the output file.  If omitted(falsy) it will use the top level program name.
  # * Binding object, as if from 'binding'
  # * A proc which returns a binding.
  #
  # If bind is passed, the proc will not be executed.  If bind is falsy, the proc will be executed and it's return value stored.
  #
  # The proc is evaluated in the context of the new MathViz instance, making #const and #input directly available
  def initialize(name = nil, bind = nil, &proc)
    @name = name || File.basename($PROGRAM_NAME, '.rb')
    @env = bind || instance_eval(&proc)
  end

  # Convert a basic value (typically Numeric) into a MathViz::Term (MathViz::Constant)
  def const(x)
    MathViz::Constant.new(x)
  end

  # Convert a basic value (typically Numeric) into a MathViz::Term (MathViz::Input)
  def input(x)
    MathViz::Input.new(x)
  end

  # Define new units (instance methods) on module MathViz::Units (where they will be picked up by everything including the module)
  # Defined methods are essentialy aliases for #unit(name); see MathViz::Measurable / MathViz::Measured
  def new_units(*units)
    MathViz::Units.new_units(*units)
  end

  # Define op as a binary operator
  def binop(op)
    MathViz::Term.binop op
    MathViz::Unit.binop op
  end

  # Define op as unary operator
  def unop(op)
    MathViz::Term.unop op
  end

  # Save a Graphviz .dot file in the current directory, with name specified in the constructor.  Triggers most of the actual processsing.
  def dot
    MathViz::Term.name_terms!(@env)
    #puts MathViz::Term.list_terms(@env).map {|t| t.long}
    graph = GraphvizR.new @name
    MathViz::Term.list_terms(@env).flat_map(&:collapse).each {|t|
      t.to_dot(graph)
    }

    filename = @name + '.dot'
    graph.output(filename, 'dot')
    puts "Wrote #{filename}"
  end

  # Comment that identifies a set of inputs.  Subsequent measured values will be marked as #input
  def When(desc)
    @@default_term = Input
  end

  # Comment that identifies a set of constants.  Subsequent measured values will be marked as #const
  def Given(desc)
    @@default_term = Constant
  end

  # Comment that identifies a section of calculations on the inputs and constants.
  def Then(desc)
    @@default_term = Constant
  end

  # Comment which reads a little better than repetition.
  def And(desc)
  end

  # internal method
  def self.default_term
    @@default_term ||= Constant
  end

  # Turn the object into a MathViz::Term (MathViz::Constant) if isn't already a MathViz::Term.  This allows for operator parameters to be primitive values without needing MathViz#const, MathViz#input, or units.
  def self.term(x)
    if (x.kind_of?(MathViz::Term))
      x
    else
      MathViz::Constant.new(x)
    end
  end
end

# Value objects that do the actual unit tracking.
# 
# Contains all the interesting power tracking and cancellation.
class MathViz::Unit
  # The interal representation.  Current implementation method is hash-of-powers; e.g. {:m => 2, :s => -1} represents m*m/s
  attr_reader :unit

  # * With a symbol, creates a simple unit.
  # * With a hash-of-powers, it simply copies those values.
  # * Otherwise, it becomes a dimensionless unit.
  def initialize(h = nil)
    @unit = Hash.new(0)
    case h
    when Hash; @unit.merge!(h); normalize!
    when Symbol; @unit[h] = 1
    end
    @unit.freeze
    freeze
  end

  # Implement a simple binary operation.  It verifies that the units match and returns the unit ERROR if not.
  def binary_operator(other)
    if (unit != other.unit)
      #p "#{to_s} !+- #{other.to_s}"
      return MathViz::Unit.new(:ERROR)
    end
    return self
  end

  def self.binop(other)
    alias_method other, :binary_operator
  end

  alias_method :+, :binary_operator
  alias_method :-, :binary_operator
  alias_method :<, :binary_operator
  alias_method :>, :binary_operator
  alias_method :==, :binary_operator
  alias_method :max, :binary_operator
  alias_method :min, :binary_operator
  alias_method :&, :binary_operator
  alias_method :|, :binary_operator

  def *(other)
    x = @unit.dup
    other.unit.each do |u,power|
      x[u] += power
    end
    MathViz::Unit.new(x)
  end

  def /(other)
    x = @unit.dup
    other.unit.each do |u,power|
      x[u] -= power
    end
    MathViz::Unit.new(x)
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
    x = units.flat_map {|u,power| [u] * power.abs }.join('*')
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
# including MathViz::Units triggers extension by MathViz::Units::Class.  MathViz::Units includes MathViz::Units::Class itself, so all those methods are available.
module MathViz::Units
  # Provides the new_units class method to all classes with units
  module Class
    # Define new units (instance methods) on module MathViz::Units (where they will be picked up by everything including the module)
    # Defined methods are essentialy aliases for #unit(name); see MathViz::Measurable / MathViz::Measured
    def new_units(*units)
      units.each do |u|
        MathViz::Units.__send__ :define_method, u do
          unit(u)
        end
      end
    end

    # extend MathViz::Units::Class
    def included(host)
      host.extend(MathViz::Units::Class)
    end
  end

  extend MathViz::Units::Class
end

# Something (i.e. Numeric) which does not have MathViz::Units, but can be turned into something which does (i.e., MathViz::Constant)
module MathViz::Measurable
  include MathViz::Units

  # return term wrapping self with the specified units; see also MathViz::Units::Class#new_units
  def unit(x)
    MathViz.default_term.new(self).unit(x)
  end

  # return term wrapping self with new units assigned to the denominator
  def per
    MathViz.default_term.new(self).per
  end

  # api method for unwrapping terms
  def to_value
    if kind_of? Numeric
      to_f
    else
      self
    end
  end
end

# Something (i.e. MathViz::Term) which has MathViz::Units.
module MathViz::Measured
  include MathViz::Units

  # Return a string representation of the units portion, with space if applicable
  def with_units
    u = units.to_s
    if (u.empty?)
      u
    else
      ' ' + u
    end
  end

  # Add the named unit to our units and return self.  See also MathViz::Units::Class#new_units
  def unit(x)
    @unit ||= MathViz::Unit.new
    @unit_sign ||= 1
    if (@unit_sign > 0)
      @unit *= MathViz::Unit.new(x)
    else
      @unit /= MathViz::Unit.new(x)
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
    @unit || MathViz::Unit.new
  end

  # api method for unwrapping terms
  def to_value
    to_f
  end
end

# Namespaced extensions
module MathViz::NumericOperations
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

class Numeric
  include MathViz::Measurable
  include MathViz::NumericOperations
end

# Namespaced extensions
module MathViz::Graphable
  # graph node title
  def node
    to_s
  end
end

class Object
  include MathViz::Graphable
end

# Base class for graphable objects.  It also contain the operators, which return MathViz::Operation subclasses.
class MathViz::Term
  include MathViz::Measured

  # Assign names to named MathViz::Terms, so the name can be effiently looked up from the MathViz::Term object.
  def self.name_terms!(env)
    eval("local_variables", env).each do |var|
      value = eval(var.to_s, env)
      if value.respond_to? :name=
        value.name = var.to_s
      end
    end
  end

  # Return a list of all MathViz::Terms accessible from a binding
  def self.list_terms(env)
    eval("local_variables", env).map { |var|
      value = eval(var.to_s, env)
      if (value.kind_of?(MathViz::Term))
        value
      else
        nil
      end
    }.compact
  end

  # Define op as a binary operator
  def self.binop(op)
    define_method(op) do |c|
      MathViz::Operation.new(op, self, c)
    end
  end

  # Define op as an unary operator
  def self.unop(op)
    define_method(op) do
      MathViz::Operation::Unary.new(op, self)
    end
  end

  # Graphviz node name; see MathViz::Term#name_terms!
  attr_accessor :name

  def to_s
    @name || anon
  end

  # A string representation of the node's data, typically calculated value with units.
  def data
    f = to_value
    if (f.kind_of?(TrueClass) || f.kind_of?(FalseClass))
      f.to_s
    elsif (!f.respond_to? :finite?)
      f.to_s + with_units
    elsif (!f.finite?)
      MathViz::Infinity.to_s
    elsif (f.floor == f)
      f.to_i.to_s + with_units
    else
      f.to_s + with_units
    end
  end

  def to_i
    f = to_value
    return MathViz::Infinity unless f.finite?
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

  # Extend Graphviz g with a representation of this object
  def to_dot(g)
    g[node] [:label => label, :shape => shape, :color => color, :style => style]
  end

  # Helper to avoid duplicate nodes
  def generated?
    !name.nil?
  end

  # Only valid after names have been assigned, which means not during graph construction
  def anonymous?
    !@name
  end

  # Stub
  def collapse(parentop = nil)
    [self]
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

# A simple number.
#
# Also identifies the number as true constant, which affects nodes display style, so that opportunities for constant-folding can be idenified.
class MathViz::Constant < MathViz::Term
  # wraps a primitive value
  def initialize(a)
    super()
    @a = a
  end

  # Debugging method; string with both name and value
  def long
    n = @name && (@name + " = ")
    "(#{n}#{to_value})"
  end

  # Forward to contained object
  def to_value
    @a.to_value
  end

  # Returns the units of the contained object (if any) or else it's own.
  def units
    if @a.respond_to? :units
      @a.units
    else
      super
    end
  end

  # Graphviz node shape
  def shape
    :plaintext
  end

  def constant?
    true
  end

  # Forward to contained object
  def finite?
    @a.respond_to?(:finite?) ? @a.finite? : true
  end
end

# A simple number.
#
# Derives most of it's behavior from MathViz::Constant, but also identifies the number as variable, which affects nodes display style, so that opportunities for constant-folding can be idenified.
class MathViz::Input < MathViz::Constant
  # Graphiviz node shape
  def shape
    :ellipse
  end

  # false
  def constant?
    false
  end
end

# n-ary operators
class MathViz::Operation < MathViz::Term
  def initialize(op, *operands)
    super()
    @op = op
    @operands = operands.map{|x| MathViz.term(x)}
  end

  # Debugging method; returns string of names and values
  def long
    n = @name && (@name + " = ")
    "(#{n}#{@op} #{@operands.join(',')} = #{to_value})"
  end

  # Graphviz node shape; differentiates comparison operators
  def shape
    if ([:>, :<, :>=, :<=, :&, :|, :==].include? @op)
      :ellipse
    else
      :box
    end
  end

  # Graphviz node color; differentiates basic mathematical operators (+, -, *, /)
  def color
    case @op
    when :+; :green;
    when :-; :yellow;
    when :*; :blue;
    when :/; :cyan;
    else     :red;
    end
  end

  # Draws edges, and ensure the from nodes is drawn
  def link_from(g, other, style, label)
    if label
      (g[other.to_s] >> g[node]) [:arrowhead => style, :headlabel => @op.to_s, :labeldistance => '2']
    else
      (g[other.to_s] >> g[node]) [:arrowhead => style]
    end
    other.to_dot(g) unless other.generated?
  end

  # Extend Graphviz g with a representation of this object, and incoming connections
  def to_dot(g)
    super
    link_from(g, @operands.first, :normal, false)
    @operands.slice(1..-1).each {|x| link_from(g, x, :onormal, true)}
  end

  # Apply the operator to create the derived value.
  def to_value
    return MathViz::Infinity unless finite?
    @operands.map(&:to_value).reduce(&@op)
  end

  # Apply the operator to create the derived units.
  def units
    @operands.map(&:units).reduce(&@op)
  end

  def constant?
    @operands.all?(&:constant?)
  end

  def finite?
    @operands.all?(&:finite?)
  end

  # Combine anonymous nodes with the same operator to simply graph
  def collapse(parentop = nil)
    @operands = @operands.flat_map {|x| x.collapse(@op)}
    if anonymous? && parentop == @op
      @operands
    else
      [self]
    end
  end
end

# Special cases for unary operators
class MathViz::Operation::Unary < MathViz::Operation
  # Apply the operator to create the derived value.
  def to_value
    return MathViz::Infinity unless finite?
    @operands.map(&:to_value).map(&@op).first
  end

  # Extend Graphviz g with a representation of this object, and incoming connections
  def to_dot(g)
    super
    @operands.each {|x| link_from(g, x, :normal, true)}
  end
end
