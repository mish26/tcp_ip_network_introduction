# nc インストール
sudo yum install nmap-ncat.x86_64

# サーバー容易
nc -ulnv 127.0.0.1 54321

# クライアント用意
nc -u 127.0.0.1 54321

# udpの通信をキャプチャする
sudo tcpdump -i lo -tnlA "udp and port 54321"
