require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/mathviz'

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'mathviz' do
  self.developer 'Justin Love', 'hg@JustinLove.name'
  self.rubyforge_name       = self.name # TODO this is default value
  self.extra_deps         = [['GraphvizR','>= 0.5.1']]
  self.extra_rdoc_files = ['README.rdoc']
end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]
