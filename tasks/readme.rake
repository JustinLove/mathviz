file "README.rdoc" => ['README.erb', 'examples/E_mc2.rb']  do |t|
  sh "erb #{t.prerequisites.first} > #{t.name}"
end