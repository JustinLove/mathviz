file "README.rdoc" => ['README.erb', 'examples/E_mc2.rb', 'examples/E_mc2.png']  do |t|
  sh "erb #{t.prerequisites.first} > #{t.name}"
end

file "examples/E_mc2.png" => ['examples/E_mc2.rb', 'lib/mathviz.rb'] do |t|
  cd 'examples' do
    ruby '-I../lib E_mc2.rb'
    sh "dot -Tpng -oE_mc2.png E_mc2.dot"
  end
end
