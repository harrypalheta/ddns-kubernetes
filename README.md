# ddns-kubernetes

## Hosts Configurations

|Host 	|Função 	                |FQDN privado 	        |Endereço IP privado
|-      |-                          |-                      |-
|ns1 	|Servidor DNS primário 	    |ns1.itbam.io 	        |10.128.10.11
|ns2 	|Servidor DNS secundário    |n2.itbam.io 	        |10.128.20.12
|host1 	|Host genérico 1 	        |host1.itbam.io 	    |10.128.100.101
|host2 	|Host genérico 2 	        |host2.itbam.io 	    |10.128.200.102

## Run infrastructure

```
vagrant up
```

## Tests

```
vagrant ssh host1
```

```
ping host2
```

# Clean Box

```
vagrant destroy -f
```

> based on: https://www.digitalocean.com/community/tutorials/how-to-configure-bind-as-a-private-network-dns-server-on-ubuntu-18-04-pt