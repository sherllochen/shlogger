$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "shlogger/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "shlogger"
  s.version     = Shlogger::VERSION
  s.authors     = ["sherllo"]
  s.email       = ["sherllochen@gmail.com"]
  s.homepage    = "http://sherllo.chen"
  s.summary     = ": Summary of Shlogger."
  s.description = ": Description of Shlogger."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  # 可执行文件，引入可用rake tasks
  s.executables = s.files.grep(%r{^lib/tasks}) { |f| File.basename(f) }

  s.add_dependency "rails", "~> 5.2.1"

  s.add_development_dependency "sqlite3"
end
