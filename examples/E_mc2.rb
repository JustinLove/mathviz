require 'mathviz'

# No units are provided by default.
# You can also use 1.unit(:m).per.unit(:s) etc.
module MathViz::Units
  new_units :m, :s, :kg, :lb, :joule
end

MathViz.new {
  # Alternate form: MathViz.new('optional_output_filename', binding_object)

  m = 140.lb * 0.45359237.kg.per.lb
  c = 299_792_458.m.per.s
  # capitalized values are constants in ruby, so we need the underscore
  _E = (m * (c * c)) * 1.joule.per.kg.m.m.per.s.s

  binding # Don't forget to return the binding
}.dot # Required to produces the actual .dot file
