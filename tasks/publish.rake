task :publish => [:idocs]  do |t|
  sh 'rm -r ~/files/web/wml/gems/mathviz'
  sh 'mv doc ~/files/web/wml/gems/mathviz'
end
