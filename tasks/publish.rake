task :publish => [:idocs]  do |t|
  target = '~/files/web/wml/gems/mathviz'
  sh "rm -r #{target}"
  sh "mv doc #{target}"
end
