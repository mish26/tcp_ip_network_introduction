# Network Namespaceの作成
sudo ip netns add lan
sudo ip netns add router
sudo ip netns add wan

# vethインターフェースの作成
sudo ip link add lan-veth0 type veth peer name gw-veth0
sudo ip link add wan-veth0 type veth peer name gw-veth1

# 作ったvethインターフェースをNetwork Namespaceに所属させる
sudo ip link set lan-veth0 netns lan
sudo ip link set gw-veth0 netns router
sudo ip link set gw-veth1 netns router
sudo ip link set wan-veth0 netns wan

# vethインターフェースをupする
sudo ip netns exec lan ip link set lan-veth0 up
sudo ip netns exec router ip link set gw-veth0 up
sudo ip netns exec router ip link set gw-veth1 up
sudo ip netns exec wan ip link set wan-veth0 up

# routerのLAN側とWAN側のそれぞれにつながるvethインターフェースにIPアドレスを付与
sudo ip netns exec router ip address add 192.0.2.254/24 dev gw-veth0
sudo ip netns exec router ip address add 203.0.113.254/24 dev gw-veth1

# router設定
sudo ip netns exec router sysctl net.ipv4.ip_forward=1

# lanのインターフェースにIPアドレスを付与
sudo ip netns exec lan ip address add 192.0.2.1/24 dev lan-veth0
# デフォルトルートを設定ここがちがう
sudo ip netns exec lan ip route add default via 192.0.2.254

# wanのインターフェースにIPアドレスを付与
sudo ip netns exec wan ip address add 203.0.113.1/24 dev wan-veth0
# デフォルトルートを設定
sudo ip netns exec wan ip route add default via 203.0.113.254

# Source NATの挙動を観察する

# iptablesでnatを設定する
## 現在のiptablesの設定を確認する
sudo ip netns exec router iptables -t nat -L

## natのルール追加
## -A POSTROUTING 処理を追加するチェインを指定。POSTROUTINGはルーティングが終わってパケットがインターフェースから出ていく直前を示している
## -s 192.0.2.0/24 送信元IP
## -o gw-veth1 \   出力先インターフェース
## -j MASQUERADE   条件に一致したルールを指定。MASQUERADEはターゲットがSourceNATであることを示している
sudo ip netns exec router iptables -t nat \
-A POSTROUTING \
-s 192.0.2.0/24 \
-o gw-veth1 \
-j MASQUERADE

# 動作確認
sudo ip netns exec lan ping -c 5 203.0.113.1
## 別画面でtcpdump
sudo ip netns exec lan tcpdump -tnl -i ns2-veth0 icmp
sudo ip netns exec wan tcpdump -tnl -i wan-veth0 icmp

# Destination NATの挙動を観察する

## natのルール追加
## -A PREROUTING 処理を追加するチェインを指定。PREROUTINGはインターフェースからパケットが入ってきた直後を表している。
## -p 処理対象のトランスポート層のプロトコル
## --dport 処理対象のポート番号
## -d 書き換える前の送信先IPアドレス
## -j DNAT 条件に一致したルールを指定。DNATはターゲットがDestination NATであることを示している
## --to-destination 書き換えた後の送信先IPアドレス
sudo ip netns exec router iptables -t nat \
-A PREROUTING \
-p tcp \
--dport 54321 \
-d 203.0.113.254 \
-j DNAT \
--to-destination 192.0.2.1

# lan側で、TCPの54321portを待ち受けるサーバーを起動
sudo ip netns exec lan nc -lnv 54321
# wan側のnetnsから、サーバーに接続する
# 接続先は、routerのグローバルIP
sudo ip netns exec wan nc 203.0.113.254 54321

# lan側のインターフェースをキャプチャしてみる
sudo ip netns exec lan tcpdump -tnl -i lan-veth0 "tcp and port 54321"
