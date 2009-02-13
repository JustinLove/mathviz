require 'matlat'

MatLat.new('dc') {
  pi = input 3.14159
  second = input 1000

  scale = input 1
  diameter = input 172
  count = input 10
  unit = input 1
  resolution = input 100
  timeMultiplier = input 1
  time = input((Time.now.to_f * 1000).floor)
  frameRate = input 1

  root_position = time / resolution
  unit_position = root_position / unit
  un_position = unit_position / count

  timels = unit * count
  ms_rev = resolution * timels
  rev_s = input(1000) / ms_rev
  real_rev_s = rev_s * timeMultiplier
  rev_timel = input(1) / timels
  configPerimeter = diameter * pi
  perimeter = configPerimeter * scale
  rev_pixel = input(1) / perimeter
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

