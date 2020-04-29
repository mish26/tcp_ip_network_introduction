# Network Namespaceの作成
sudo ip netns add ns1
sudo ip netns add ns2
sudo ip netns add ns3

# vethインターフェースの作成
sudo ip link add ns1-veth0 type veth peer name ns1-br0
sudo ip link add ns1-veth0 type veth peer name gw-veth0
sudo ip link add ns2-veth0 type veth peer name gw-veth1

# 作ったvethインターフェースをNetwork Namespaceに所属させる
sudo ip link set ns1-veth0 netns ns1
sudo ip link set ns2-veth0 netns ns2
sudo ip link set ns3-veth0 netns ns3

# vethインターフェースをupする
sudo ip netns exec ns1 ip link set ns1-veth0 up
sudo ip netns exec ns2 ip link set ns2-veth0 up
sudo ip netns exec ns3 ip link set ns3-veth0 up

# vethインターフェースにIPアドレスを付与
sudo ip netns exec ns1 ip address add 192.0.2.1/24 dev ns1-veth0
sudo ip netns exec ns2 ip address add 192.0.2.2/24 dev ns2-veth0
sudo ip netns exec ns3 ip address add 192.0.2.3/24 dev ns3-veth0

# MACアドレス変更
sudo ip netns exec ns1 ip link set dev ns1-veth0 address 00:00:5E:00:53:01
sudo ip netns exec ns2 ip link set dev ns2-veth0 address 00:00:5E:00:53:02
sudo ip netns exec ns3 ip link set dev ns3-veth0 address 00:00:5E:00:53:03

# Network Bridge
sudo ip link add dev br0 type bridge
sudo ip link set br0 up
sudo ip link set ns1-br0 master br0
sudo ip link set ns2-br0 master br0
sudo ip link set ns3-br0 master br0
sudo ip link set ns1-br0 up
sudo ip link set ns2-br0 up
sudo ip link set ns3-br0 up

# 動作確認
# tcpdumpでicmpのメッセージを観測
sudo ip netns exec ns2 tcpdump -tnel -i ns2-veth0 icmp
sudo ip netns exec ns1 ping -c 3 192.0.2.2 -I 192.0.2.1
sudo ip netns exec ns1 ping -c 3 192.0.2.3 -I 192.0.2.1

# ブリッジのMACアドレステーブルを確認
bridge fdb show br br0
