#
# Kitchen Rakes? Sure!
require "capistrano/cli"
require "fileutils"

namespace :warehouse do
  desc "bootstraps a new ShippingContainer package"
  task :new_container do
    name = ENV["PACKAGE"]
    name ||= Capistrano::CLI.ui.ask "What's the package name?"
    FileUtils.mkdir_p("warehouse/#{name}/files")
    `echo "/* configure #{name}'s defaults and file dependencies here */\n{\n  \\\"defaults\\\":{},\n  \\\"files\\\":[]\n}" > warehouse/#{name}/config.json`
    `echo "echo 'Hello, world!'" > warehouse/#{name}/install.mustache`
    puts "An empty container has been created in #{File.expand_path("warehouse/#{name}")}"
  end
end