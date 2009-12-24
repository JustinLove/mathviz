file "README.rdoc" => 'README.erb' do |t|
  sh "erb #{t.prerequisites.join(' ')} > #{t.name}"
end