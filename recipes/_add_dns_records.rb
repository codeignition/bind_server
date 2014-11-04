dns_config    = data_bag_item(:dns, "config")
domain        = dns_config['domain']
rev_domain    = dns_config['rev_domain']
dns_server_ip = node.ipaddress
dns_key_name  = dns_config['key_name']
dns_key_value = dns_config['key_value']

execute 'yum groupinstall -y "Developer Tools"'
require 'rubygems'
chef_gem "fog"
require 'fog'

chef_gem "chef-vault"
require "chef-vault"
s3cmd_aws_creds = ChefVault::Item.load("aws", "s3cmd")

# create a connection
connection = Fog::Compute.new({
  :provider                 => 'AWS',
  :aws_access_key_id        => s3cmd_aws_creds['access_key'],
  :region                   => 'us-east-1',
  :aws_secret_access_key    => s3cmd_aws_creds['secret_key']
})

server_list =Hash.new(0)
connection.servers.all.each do |server|
  if server.state.to_s.downcase == "running"
    server_list[server.tags["Name"].to_s.split(" - ")[-1].gsub(" ","-").gsub("_", "-")] = server.private_ip_address.to_s
  end
end

puts server_list

server_list.each do |a_record,ipaddress|
  execute "nsupdate a_record" do
    command <<-END
cat<<EOF | /usr/bin/nsupdate -y #{dns_key_name}:#{dns_key_value} -v
server #{dns_server_ip}
zone #{domain}
update delete #{a_record}.#{domain} A
update add  #{a_record}.#{domain} 60 A #{ipaddress}
send
EOF
    END
    not_if "nslookup #{a_record}.#{domain} #{dns_server_ip} | grep #{ipaddress}"
  end

  rev_ip = ipaddress.split(".").reverse[0..1].join(".")

  execute "nsupdate PTR record #{ipaddress}" do
    command <<-END
cat<<EOF |/usr/bin/nsupdate -y #{dns_key_name}:#{dns_key_value} -v
server #{dns_server_ip}
zone #{rev_domain}
update delete #{rev_ip}.#{rev_domain} PTR
update add #{rev_ip}.#{rev_domain} 60 PTR #{a_record}.#{domain}
send
EOF
    END
    not_if "nslookup #{ipaddress} #{dns_server_ip} | grep #{a_record}"
  end
end

cname_servers = {}
node["servers"]["cname"].each do |cname,recipe|
  nodes = search(:node, "run_list:recipe\\[#{recipe}\\]")
  count = 1
  nodes.each do |node|
    cname_servers["#{cname}0#{count}"] = node.name
    count += 1
  end
end
cname_servers.each do |cname_record,a_record|
  execute "nsupdate cname record #{cname_record}" do
    command <<-END
cat<<EOF |/usr/bin/nsupdate -y #{dns_key_name}:#{dns_key_value} -v
server #{dns_server_ip}
zone #{domain}
update delete #{cname_record}.#{domain} CNAME
update add  #{cname_record}.#{domain} 60 CNAME #{a_record}.#{domain}
send
EOF
    END
    not_if "nslookup #{cname_record}.#{domain} #{dns_server_ip} | grep #{a_record}"
  end
end
