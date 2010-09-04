require 'mathviz'

MathViz.new('first') {
  pi = const 3.14159

  scale = input 1.0
  size = const 172
  count = const 60
  unit = const 1
  calcUnit = const 1000
  timeMultiplier = const 1
  time = input 859294
  ms = time + 500

  root_position = time / calcUnit
  unit_position = root_position / unit
  un_position = unit_position / count

  root_to = ms / calcUnit
  unit_to = root_to / unit
  un_to = unit_to / count

  relativeTime = count * unit * calcUnit
  perimeter = size * scale * pi
  pixel = const(1) / perimeter
  tick = relativeTime * pixel
  realTime = calcUnit.min(tick.max(1000))
  delay = realTime / timeMultiplier
  threashold = delay * 2
  delta = un_to - un_position
  timeDelta = relativeTime * delta
  
  binding
}.dot
