#
# Cookbook Name:: dns_server
# Recipe:: default
#
# Copyright 2014, Ajey Gore
#
# All rights reserved - Provided as is, without warranty
#


#Install required packages
%w(bind bind-utils bind-libs).each do |bind_package|
  package bind_package
end

#For some strange reason we need development tools it should not be required

execute 'yum groupinstall -y "Development Tools"'

service "named" do
  service_name "named"
  supports :restart => true
  action [:enable, :start]
end

dns_config = data_bag_item(:dns, "config")

template "/var/named/data/#{zone}.zone" do
  source "dns_server/domain.zone.erb"
  mode "644"
  owner "named"
  group "named"
  variables(
    domain: dns_config['domain'],
    ipaddress: node.ipaddress
  )
  action :create_if_missing
  notifies :restart, "service[named]"
end

template "/var/named/data/#{zone}.rev" do
  source "dns_server/domain.rev.erb"
  mode "644"
  owner "named"
  group "named"
  variables(
    domain: dns_config['domain'],
    rev_domain: dns_config['rev_domain'],
    ipaddress: node.ipaddress

  )
  action :create_if_missing
  notifies :restart, "service[named]"
end

template "/etc/named.conf" do
  source "dns_server/named.conf.erb"
  mode "644"
  owner "named"
  group "named"
  variables(
    domain: dns_config['domain'],
    ipaddress: node.ipaddress,
    key_name: dns_config['key_name'],
    key_value: dns_config['key_value'],
    rev_domain: dns_config['rev_domain'],
    subnet: dns_config['subnet'],
    regions: ["us-east-1.compute.internal"],
    ec2_dns_server: "10.50.0.2"
  )
  action :create
  notifies :restart, "service[named]", :immediately
end

script "iptables for tcp port 53" do
  interpreter "bash"
  user "root"
  code <<-EOH
  iptables -I INPUT 1 -s 0/0 -p tcp --destination-port 53 -m state --state NEW,ESTABLISHED -j ACCEPT
  iptables -I OUTPUT 2 -d 0/0 -p tcp --source-port 53 -m state --state ESTABLISHED -j ACCEPT
  service iptables save
  EOH
  not_if "service iptables status | grep 'tcp dpt:53'"
end

script "iptables for udp port 53" do
  interpreter "bash"
  user "root"
  code <<-EOH
    iptables -I INPUT 1 -s 0/0 -p udp --destination-port 53 -m state --state NEW,ESTABLISHED -j ACCEPT
  iptables -I OUTPUT 2 -d 0/0 -p udp --source-port 53 -m state --state ESTABLISHED -j ACCEPT
  service iptables save
  EOH
  not_if "service iptables status | grep 'udp dpt:53'"
end

include_recipe "dns_server::_add_dns_records"

#Finally schedule chef client to run every 2 minute to update all records
cron "chef-client" do
  minute "*/2"
  hour "*"
  command "chef-client"
end
