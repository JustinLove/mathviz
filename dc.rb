require 'matlat'

MatLat.new('dc') {
  pi = const 3.14159
  second = const 1000

  scale = input 1
  diameter = const 172
  count = const 10
  unit = const 1
  resolution = const 100
  timeMultiplier = const 1
  time = input((Time.now.to_f * 1000).floor)
  frameRate = input 1

  root_position = time / resolution
  unit_position = root_position / unit
  un_position = unit_position / count

  timels = unit * count
  ms_rev = resolution * timels
  rev_s = const(1000) / ms_rev
  real_rev_s = rev_s * timeMultiplier
  rev_timel = const(1) / timels
  configPerimeter = diameter * pi
  perimeter = configPerimeter * scale
  rev_pixel = const(1) / perimeter
  tick = rev_timel.min(rev_pixel.max(rev_s))
  threshold = tick * 2
  real_ms_rev = ms_rev / timeMultiplier
  delay = tick * real_ms_rev

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
  animatable = real_rev_s < 0.01
  jump = big & animatable
  superfast = real_rev_s > 1.5

  binding
}.dot

