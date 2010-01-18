task :publish => [:idocs]  do |t|
  target = File.expand_path '~/files/web/wml/gems/mathviz'
  rm_r(target) if File.exist?(target)
  mv 'doc', target
end
