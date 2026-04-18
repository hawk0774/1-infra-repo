[masters]
%{ for i, ip in masters ~}
master${i+1} ansible_host=${ip} node_name=master${i+1} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519 ansible_become=yes ansible_become_method=sudo
%{ endfor ~}

[workers]
%{ for i, ip in workers ~}
worker${i+1} ansible_host=${ip} node_name=worker${i+1} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519 ansible_become=yes ansible_become_method=sudo
%{ endfor ~}

[first_master]
master1

[all:vars]
lb_ip=${lb_ip}
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
