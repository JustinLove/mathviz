task :publish => [:idocs]  do |t|
  begin
    rm '~/files/web/wml/gems/mathviz'
  rescue
  end
  `mv doc ~/files/web/wml/gems/mathviz`
end
