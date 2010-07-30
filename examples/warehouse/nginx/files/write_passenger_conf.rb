root = ENV["GEM_PATH"].split(":").first
passenger = `gem list | grep passenger`
version = passenger.match(/passenger \((.+)\)/)[1]
passenger_home = File.join(root, "gems", "passenger-#{version}")
passenger_ruby = `which ruby`.chomp

File.open("/etc/nginx/conf.d/passenger.conf", "w+") do |f|
  f.puts "passenger_root #{passenger_home};"
  f.puts "passenger_ruby #{passenger_ruby};"
end