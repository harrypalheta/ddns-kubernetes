#!/bin/bash
hostname_add=$1
ip_add=$2

## add host in name.conf.options ns2"
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
systemctl reload bind9
echo "Configurações aplicadas!"