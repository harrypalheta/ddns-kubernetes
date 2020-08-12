Vagrant.configure("2") do |config|

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 1
    vb.memory = "1024"
  end

  config.vm.box_check_update = false
  
  config.vm.define "ns1" do |n1|
    n1.vm.box = "ubuntu/bionic64"
    n1.vm.network "private_network", ip: "10.128.10.11"
    n1.vm.hostname = "ns1"
    n1.vm.provision "file", source: "ns1-hostctl.sh", destination: "/home/vagrant/"
    n1.vm.provision :shell, privileged: true, inline: $configure_primary_nameserver
  end
  
  config.vm.define "ns2" do |n2|
    n2.vm.box = "ubuntu/bionic64"
    n2.vm.network "private_network", ip: "10.128.20.12"
    n2.vm.hostname = "ns2"
    n2.vm.provision "file", source: "ns2-hostctl.sh", destination: "/home/vagrant/"
    n2.vm.provision :shell, privileged: true, inline: $configure_secondary_nameserver
  end

  config.vm.define "host1" do |h1|
    h1.vm.box = "ubuntu/bionic64"
    h1.vm.network "private_network", ip: "10.128.100.101"
    h1.vm.hostname = "host1"
    h1.vm.provision :shell, privileged: true, inline: $configure_hosts
  end

  config.vm.define "host2" do |h2|
    h2.vm.box = "ubuntu/bionic64"
    h2.vm.network "private_network", ip: "10.128.200.102"
    h2.vm.hostname = "host2"
    h2.vm.provision :shell, privileged: true, inline: $configure_hosts
  end
  
#   config.vm.define :master do |master|
#     master.vm.box = "ubuntu/xenial64"
#     master.vm.hostname = "master"
#     master.vm.network :private_network, ip: "10.128.30.20"
#     master.vm.provision :shell, privileged: true, inline: $install_common_tools
#     master.vm.provision :shell, privileged: false, inline: $provision_master_node
#   end

#   %w{worker1 worker2}.each_with_index do |name, i|
#     config.vm.define name do |worker|
#       worker.vm.box = "ubuntu/xenial64"
#       worker.vm.hostname = name
#       worker.vm.network :private_network, ip: "10.128.30.#{i + 21}"
#       worker.vm.provision :shell, privileged: true, inline: $install_common_tools
#       worker.vm.provision :shell, privileged: false, inline: <<-SHELL
# sudo /vagrant/join.sh
# echo 'Environment="KUBELET_EXTRA_ARGS=--node-ip=10.128.30.#{i + 21}"' | sudo tee -a /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
# sudo systemctl daemon-reload
# sudo systemctl restart kubelet
# SHELL
#     end
#   end

#   config.vm.provision "shell", inline: $install_multicast
end

$configure_primary_nameserver = <<-SCRIPT
# updates packages
apt-get update

# install dependencies
apt-get install bind9 bind9utils bind9-doc -y

# bind mode ipv4
sed -i "s|-u bind|-u bind -4|g" /etc/default/bind9

# restart bind
systemctl restart bind9

# configuring trusted customers
cat > /etc/bind/named.conf.options <<EOF
acl "trusted" {
  10.128.10.11;    # ns1 - can be set to localhost
  10.128.20.12;    # ns2
  10.128.100.101;  # host1
  10.128.200.102;  # host2
  #10.128.30.20;    # master
  #10.128.30.21;    # worker 1
  #10.128.30.22;    # worker 2
};

options {
  directory "/var/cache/bind";
  
  recursion yes;                 # enables resursive queries
  allow-recursion { trusted; };  # allows recursive queries from "trusted" clients
  listen-on { 10.128.10.11; };   # ns1 private IP address - listen on private network only
  allow-transfer { none; };      # disable zone transfers by default

  forwarders {
    8.8.8.8;
    8.8.4.4;
  };

  dnssec-validation auto;

  auth-nxdomain no;    # conform to RFC1035
  listen-on-v6 { any; };

};
EOF

# configuring zones
cat > /etc/bind/named.conf.local <<EOF
zone "itbam.io" {
  type master;
  file "/etc/bind/zones/db.itbam.io"; # zone file path
  allow-transfer { 10.128.20.12; };   # ns2 private IP address - secondary
};

zone "128.10.in-addr.arpa" {
  type master;
  file "/etc/bind/zones/db.10.128";  # 10.128.0.0/16 subnet
  allow-transfer { 10.128.20.12; };  # ns2 private IP address - secondary
};
EOF

# create zone path
mkdir /etc/bind/zones

# copy template for configure db zone
#cp /etc/bind/db.local /etc/bind/zones/db.itbam.io

# create zones
cat > /etc/bind/zones/db.itbam.io <<EOF
;
; BIND data file for local loopback interface
;
\\$TTL    604800
@       IN      SOA     itbam.io. admin.itbam.io. (
                              3         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL

; name servers - NS records
    IN      NS      ns1.itbam.io.
    IN      NS      ns2.itbam.io.

; name servers - A records
ns1.itbam.io.          IN      A       10.128.10.11
ns2.itbam.io.          IN      A       10.128.20.12

; 10.128.0.0/16 - A records
host1.itbam.io.        IN      A      10.128.100.101
host2.itbam.io.        IN      A      10.128.200.102
;master.itbam.io.       IN      A      10.128.30.20
;worker1.itbam.io.      IN      A      10.128.30.21
;worker2.itbam.io.      IN      A      10.128.30.22
EOF

# create reverse zones
cat > /etc/bind/zones/db.10.128 <<EOF
\\$TTL    604800
@       IN      SOA     itbam.io. admin.itbam.io. (
                              3         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
; name servers
      IN      NS      ns1.itbam.io.
      IN      NS      ns2.itbam.io.

; PTR Records
11.10   IN      PTR     ns1.itbam.io.    ; 10.128.10.11
12.20   IN      PTR     ns2.itbam.io.    ; 10.128.20.12
101.100 IN      PTR     host1.itbam.io.  ; 10.128.100.101
102.200 IN      PTR     host2.itbam.io.  ; 10.128.200.102
;20.30   IN      PTR     master.itbam.io.  ; 10.128.30.20
;21.30   IN      PTR     worker1.itbam.io.  ; 10.128.30.21
;22.30   IN      PTR     worker2.itbam.io.  ; 10.128.30.22
EOF

# check bind syntax config
named-checkconf

# check all zones configurations
named-checkzone itbam.io /etc/bind/zones/db.itbam.io

# check all reverse zones configurations
named-checkzone 128.10.in-addr.arpa /etc/bind/zones/db.10.128

# restart bind for apply configurations
systemctl restart bind9

# allow bind in firewall
ufw allow Bind9

# ns-hostctl
mv /home/vagrant/ns1-hostctl.sh /usr/local/bin/ns-hostctl
chmod +x /usr/local/bin/ns-hostctl
SCRIPT

$configure_secondary_nameserver = <<-SCRIPT
# updates packages
apt-get update

# install dependencies
apt-get install bind9 bind9utils bind9-doc -y

# bind mode ipv4
sed -i "s|-u bind|-u bind -4|g" /etc/default/bind9

# restart bind
systemctl restart bind9

# configuring trusted customers
cat > /etc/bind/named.conf.options <<EOF
acl "trusted" {
  10.128.10.11;    # ns1 - can be set to localhost
  10.128.20.12;    # ns2
  10.128.100.101;  # host1
  10.128.200.102;  # host2
  #10.128.30.20;    # master
  #10.128.30.21;    # worker 1
  #10.128.30.22;    # worker 2
};

options {
  directory "/var/cache/bind";
  
  recursion yes;                 # enables resursive queries
  allow-recursion { trusted; };  # allows recursive queries from "trusted" clients
  listen-on { 10.128.20.12; };   # ns2 private IP address
  allow-transfer { none; };      # disable zone transfers by default

  forwarders {
    8.8.8.8;
    8.8.4.4;
  };

  dnssec-validation auto;

  auth-nxdomain no;    # conform to RFC1035
  listen-on-v6 { any; };

};
EOF

# configuring zones
cat > /etc/bind/named.conf.local <<EOF
zone "itbam.io" {
  type slave;
  file "db.itbam.io";
  masters { 10.128.10.11; };  # ns1 private IP
};

zone "128.10.in-addr.arpa" {
  type slave;
  file "db.10.128";
  masters { 10.128.10.11; };  # ns1 private IP
};
EOF

# check bind syntax config
named-checkconf

# restart bind for apply configurations
systemctl restart bind9

# allow bind in firewall
ufw allow Bind9

# ns-hostctl
mv /home/vagrant/ns2-hostctl.sh /usr/local/bin/ns-hostctl
chmod +x /usr/local/bin/ns-hostctl
SCRIPT

$configure_hosts = <<-SCRIPT
# configure network for client
cat > /etc/netplan/00-private-nameservers.yaml <<EOF
network:
    version: 2
    ethernets:
        enp0s8:                                 # Private network interface
            nameservers:
                addresses:
                - 10.128.10.11                # Private IP for ns1
                - 10.128.20.12                # Private IP for ns2
                search: [ itbam.io ]  # DNS zone
EOF

netplan apply

systemd-resolve --status
SCRIPT

$install_common_tools = <<-SCRIPT
# bridged traffic to iptables is enabled for kube-router.
cat >> /etc/ufw/sysctl.conf <<EOF
net/bridge/bridge-nf-call-ip6tables = 1
net/bridge/bridge-nf-call-iptables = 1
net/bridge/bridge-nf-call-arptables = 1
EOF

# disable swap
swapoff -a
sed -i '/swap/d' /etc/fstab

# Install kubeadm, kubectl and kubelet
export DEBIAN_FRONTEND=noninteractive
apt-get -qq install ebtables ethtool
apt-get -qq update
apt-get -qq install -y docker.io apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get -qq update
apt-get -qq install -y kubelet kubeadm kubectl
SCRIPT

$provision_master_node = <<-SHELL
OUTPUT_FILE=/vagrant/join.sh
rm -rf $OUTPUT_FILE

# Start cluster
sudo kubeadm init --apiserver-advertise-address=10.0.0.10 --pod-network-cidr=10.244.0.0/16 | grep "kubeadm join" > ${OUTPUT_FILE}
chmod +x $OUTPUT_FILE

# Configure kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Fix kubelet IP
echo 'Environment="KUBELET_EXTRA_ARGS=--node-ip=10.0.0.10"' | sudo tee -a /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# Configure flannel
curl -o kube-flannel.yml https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
sed -i.bak 's|"/opt/bin/flanneld",|"/opt/bin/flanneld", "--iface=enp0s8",|' kube-flannel.yml
kubectl create -f kube-flannel.yml

sudo systemctl daemon-reload
sudo systemctl restart kubelet
SHELL

$install_multicast = <<-SHELL
apt-get -qq install -y avahi-daemon libnss-mdns
SHELL
