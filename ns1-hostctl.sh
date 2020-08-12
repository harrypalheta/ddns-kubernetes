#!/bin/bash
hostname_add=$1
ip_add=$2
domain=$3
file="/etc/bind/zones/db.${domain}"

## add host to routing zone 
if grep --quiet ${hostname_add} ${file} || grep --quiet ${ip_add} ${file}
then
echo "O Hostname ou IP já existe na Zona de Encaminhamento!"
else
  echo -e "${hostname_add}.${domain}.\t\tIN\tA\t${ip_add}" >> $file
  echo "Hostname ${hostname_add} adicionado ao arquivo $file"
fi

## add host to reverse zone
reverse_ip=`echo $ip_add | awk -F. '{print $4"."$3}'`
prefix_ip=$(echo $ip_add | awk -F. '{print $1"."$2}')
file2="/etc/bind/zones/db.${prefix_ip}"
if grep --quiet ${hostname_add} ${file2} || grep --quiet ${reverse_ip} ${file2}
then
echo "O Hostname ou IP já existe na Zona Reversa!"
else
  echo -e "${reverse_ip}\tIN\tPTR\t${hostname_add}.${domain}.\t; ${ip_add}" >> $file2
  echo "Hostname ${hostname_add} adicionado ao arquivo $file2"
fi

## add host in name.conf.options ns1 and ns2"
file3="/etc/bind/named.conf.options"
host_line=`grep -E -o "^acl.*trusted.*\{" $file3 | wc -l`
if grep --quiet ${ip_add} ${file3}
then
echo "Este IP já existe  na ACL “confiáveis”!"
else
  sed -i "$(($host_line))s/$/\n\t$(echo $ip_add)\;\ \#\ ${hostname_add}/" $file3
  echo "Ip ${ip_add} adicionado ao arquivo $file3"
fi

echo "Aplicando as configurações..."
named-checkconf
named-checkzone ${domain} /etc/bind/zones/db.${domain}
named-checkzone ${reverse_ip}.in-addr.arpa /etc/bind/zones/db.${prefix_ip}
systemctl reload bind9
echo "Configurações aplicadas!"