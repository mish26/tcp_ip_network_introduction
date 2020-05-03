# サーバー用意
nc -lnv 127.0.0.1 54321

# クライアント用意
nc 127.0.0.1 54321

# udpの通信をキャプチャする
sudo tcpdump -i lo -tnlA "tcp and port 54321"
