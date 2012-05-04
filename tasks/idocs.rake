task :idocs => [:redocs, 'README.rdoc', 'examples/E_mc2.png', 'doc/examples']  do |t|
  cp 'examples/E_mc2.png', 'doc/examples/'
end

directory 'doc/examples'

task :redocs do |t|
  sh 'rdoc --exclude examples --exclude Gemfile --exclude Manifest.txt'
end
