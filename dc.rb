require 'matlat'

module Units
  new_units :ms, :s, :frame
  new_units :rev, :xx
  new_units :pixel, :timel
end

MatLat.new('dc') {
  pi = const 3.14159
  second = 1000.ms.per.s

  scale = input 1
  diameter = 172.pixel
  count = 10.xx.per.rev
  unit = 1.per.xx
  resolution = 100.ms
  timeMultiplier = const 1
  time = input((Time.now.to_f * 1000).floor).ms
  frameRate = input 1.frame.per.s

  root_position = time / resolution
  unit_position = root_position / unit
  un_position = unit_position / count

  timels = unit * count
  ms_rev = resolution * timels
  rev_s = const(1000.ms.per.s) / ms_rev
  real_rev_s = rev_s * timeMultiplier
  rev_timel = const(1) / timels
  configPerimeter = diameter * pi
  perimeter = configPerimeter * scale
  rev_pixel = const(1.rev) / perimeter
  tick = rev_timel.min((rev_pixel * 1.pixel).max(rev_s * 1.s))
  threshold = tick * 2
  real_ms_rev = ms_rev / timeMultiplier
  delay = tick * real_ms_rev

  step = second / frameRate
  passed = step * (timeMultiplier * 1.frame)
  #passed = delay * timeMultiplier
  ms = time + passed

  root_to = ms / resolution
  unit_to = root_to / unit
  un_to = unit_to / count

  delta = un_to - un_position
  big = delta > threshold
  visible = delta > rev_pixel
  animatable = real_rev_s < 0.01.rev.per.s
  jump = big & animatable
  superfast = real_rev_s > 1.5.rev.per.s

  binding
}.dot

