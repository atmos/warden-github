require 'rake/gempackagetask'
require 'rubygems/specification'
require 'date'
require 'bundler'

require 'lib/warden-github/version'

task :default => [:spec]

require 'spec/rake/spectask'
desc "Run specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = %w(-fs --color)
  t.spec_opts << '--loadby' << 'random'
end
