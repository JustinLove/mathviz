task :idocs => [:redocs, 'README.rdoc', 'examples/E_mc2.png']  do |t|
  mkdir 'doc/examples'
  cp 'examples/E_mc2.png', 'doc/examples/'
end
