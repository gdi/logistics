spec = Gem::Specification.new do |s|
  s.platform      =   Gem::Platform::RUBY
  s.name          =   "logistics"
  s.version       =   "0.1.0"
  s.author        =   "Matt Wilson"
  s.email         =   "development@greenviewdata.com"
  s.summary       =   "Simple remote installation and configuration system"
  s.files         =   Dir.glob('lib/**/*.rb')
  s.require_path  =   "lib"
  s.test_files    =   Dir.glob('spec/**/*') + Dir.glob('stories/**/*')
  s.has_rdoc      =   false
  s.add_dependency('yajl-ruby')
  s.add_dependency('mustache')
  s.add_dependency('net-ssh')
end