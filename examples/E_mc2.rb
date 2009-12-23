require 'example_helper'

module Units
  new_units :m, :s, :kg, :lb, :joule
end

MathViz.new {

  m = 140.lb * 0.45359237.kg.per.lb
  c = 299_792_458.m.per.s
  # capitalized values are constants in ruby, so we need the underscore
  _E = (m * (c * c)) * 1.joule.per.kg.m.m.per.s.s

  binding
}.dot

