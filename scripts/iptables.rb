# chown root myscript
# chmod u+s myscript

def ban ip
  if system("iptables -A INPUT -s #{ip} -p tcp --destination-port 80 -j DROP")
    File.open('../log/iptables.log', 'a') do |f|
      f.puts "Successfully ban: #{ip}"
    end
  else
    File.open('../log/iptables.log', 'a') do |f|
      f.puts "Error ban: #{ip}"
    end

  end
end

while(true)




end