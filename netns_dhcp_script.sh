# Network Namespaceの作成
sudo ip netns add server
sudo ip netns add client

# vethインターフェースの作成
sudo ip link add s-veth0 type veth peer name c-veth0

# 作ったvethインターフェースをNetwork Namespaceに所属させる
sudo ip link set s-veth0 netns server
sudo ip link set c-veth0 netns client

# 所属させたvethインターフェースをUPに設定する
sudo ip netns exec server ip link set s-veth0 up
sudo ip netns exec client ip link set c-veth0 up

# IPアドレス付与
sudo ip netns exec server ip address add 192.0.2.254/24 dev s-veth0

# dnsmasqインストール
sudo yum -y install dnsmasq

# dnsmasqコマンドの実行して、DHCPサーバーを起動
sudo ip netns exec server dnsmasq \
--dhcp-range=192.0.2.100,192.0.2.200,255.255.255.0 \
--interface=s-veth0 \
--no-daemon

# 別ターミナルで、DHCPクライアント実行
sudo ip netns exec client dhclient c-veth0

# ipアドレスが付与されたか確認してみる
sudo ip netns exec client ip address show | grep "inet "
sudo ip netns exec client ip route show
