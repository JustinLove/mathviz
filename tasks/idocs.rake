task :idocs => [:redocs, 'README.rdoc', 'examples/E_mc2.png', 'doc/examples']  do |t|
  cp 'examples/E_mc2.png', 'doc/examples/'
end

directory 'doc/examples'

task :redocs => [:clobber_docs] do |t|
  sh 'rdoc lib README.rdoc'
end
