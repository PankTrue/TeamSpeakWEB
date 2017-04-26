# chown root myscript
# chmod u+s myscript

if system("iptables -A INPUT -s #{ARGV[0]} -p tcp --destination-port 80 443 -j DROP")
  File.open('iptables.log', 'a') do |f|
    f.puts "Error ban: #{ARGV[0]}"
  end

else

  File.open('iptables.log', 'a') do |f|
    f.puts "Successfully ban: #{ARGV[0]}"
  end

end