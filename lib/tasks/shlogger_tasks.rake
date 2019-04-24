require 'fileutils'

namespace :shlogger do
  desc "Explaining what the task does"
  task :install do
    puts 'Install Shlogger'
    puts 'Copy shloggers.rb to Initializers'
    initializer_path = Shlogger::Engine.root.join("config", "initializers", "shlogger.rb")
    FileUtils.copy_file(initializer_path, Rails.root.join("config", "initializers", 'shlogger.rb'))
    puts 'Done'
  end
end