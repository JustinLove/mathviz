task :publish => [:idocs]  do |t|
  target = File.expand_path '~/cache/web/PN/JLN/gems/mathviz'
  rm_r(target) if File.exist?(target)
  mv 'doc', target
end
