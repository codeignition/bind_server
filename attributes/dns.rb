default[:set_fqdn] = "*.#{zone}.local"

default[:servers][:cname]={
  "jenkins"=> 'ci\:\:server',
  "chef"   => 'chef\:\:default',
  "vpn"   => 'vpn\:\:default',
  "dns" => 'bind_server\:\:default',
}
