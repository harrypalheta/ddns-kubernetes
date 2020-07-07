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
    n1.vm.provision :shell, privileged: false, inline: $configure_primary_nameserver
  end
  
  config.vm.define "ns2" do |n2|
    n1.vm.box = "ubuntu/bionic64"
    n2.vm.network "private_network", ip: "10.128.20.12"
    n2.vm.hostname = "ns2"
    n2.vm.provision :shell, privileged: false, inline: $configure_secondary_nameserver
  end

  config.vm.define "host1" do |h1|
    h1.vm.box = "ubuntu/bionic64"
    h1.vm.network "private_network", ip: "10.128.100.101"
    h1.vm.hostname = "host1"
    h1.vm.provision :shell, privileged: false, inline: $configure_hosts
  end

  config.vm.define "host2" do |h2|
    h2.vm.box = "ubuntu/bionic64"
    h2.vm.network "private_network", ip: "10.128.200.102"
    h2.vm.hostname = "host2"
    h2.vm.provision :shell, privileged: false, inline: $configure_hosts
  end
  
  config.vm.define :master do |master|
    master.vm.box = "ubuntu/xenial64"
    master.vm.hostname = "master"
    master.vm.network :private_network, ip: "10.128.30.20"
    master.vm.provision :shell, privileged: true, inline: $install_common_tools
    master.vm.provision :shell, privileged: false, inline: $provision_master_node
  end

  %w{worker1 worker2}.each_with_index do |name, i|
    config.vm.define name do |worker|
      worker.vm.box = "ubuntu/xenial64"
      worker.vm.hostname = name
      worker.vm.network :private_network, ip: "10.128.30.#{i + 21}"
      worker.vm.provision :shell, privileged: true, inline: $install_common_tools
      worker.vm.provision :shell, privileged: false, inline: <<-SHELL
sudo /vagrant/join.sh
echo 'Environment="KUBELET_EXTRA_ARGS=--node-ip=10.128.30.#{i + 21}"' | sudo tee -a /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sudo systemctl daemon-reload
sudo systemctl restart kubelet
SHELL
    end
  end

  config.vm.provision "shell", inline: $install_multicast
end

$configure_primary_nameserver = <<-SCRIPT
sudo apt-get update
sudo apt-get install bind9 bind9utils bind9-doc
sudo vi /etc/default/bind9
sudo systemctl restart bind9
sudo nano /etc/bind/named.conf.options
sudo vi /etc/bind/named.conf.options
nano /etc/bind/named.conf.local
sudo mkdir /etc/bind/zones
sudo cp /etc/bind/db.local /etc/bind/zones/db.test.itbam.io
sudo vi /etc/bind/zones/db.test.itbam.io
cat /etc/bind/zones/db.test.itbam.io
sudo vi /etc/bind/zones/db.test.itbam.io
sudo cp /etc/bind/db.127 /etc/bind/zones/db.10.128
sudo vi /etc/bind/zones/db.10.128
cat /etc/bind/zones/db.test.itbam.io
cat /etc/bind/zones/db.10.128 
sudo named-checkconf
sudo named-checkzone test.itbam.io db.test.itbam.io
sudo nano /etc/bind/named.conf.local
sudo named-checkzone test.itbam.io db.test.itbam.io
cat /etc/bind/named.conf.local
cat /etc/bind/zones/db.test.itbam.io
sudo named-checkzone test.itbam.io db.test.itbam.io
sudo named-checkzone test.itbam.io /etc/bind/zones/db.test.itbam.io
sudo named-checkzone 128.10.in-addr.arpa /etc/bind/zones/db.10.128
sudo systemctl restart bind9
sudo ufw allow Bind9
SCRIPT

$configure_secondary_nameserver = <<-SCRIPT
sudo apt-get update
sudo apt-get install bind9 bind9utils bind9-doc -y
sudo nano /etc/default/bind9
sudo systemctl restart bind9
sudo nano /etc/bind/named.conf.options
sudo nano /etc/bind/named.conf.local
sudo named-checkconf
sudo systemctl restart bind9
sudo ufw allow Bind9
SCRIPT

$configure_hosts = <<-SCRIPT
ip address show to 10.128.0.0/16
sudo vi /etc/netplan/00-private-nameservers.yaml
sudo netplan try
sudo systemd-resolve --status
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
