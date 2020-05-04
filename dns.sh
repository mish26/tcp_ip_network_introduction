sudo tcpdump -tnl -i anu  "udp and port 53"
dig +short @8.8.8.8 example.org A
