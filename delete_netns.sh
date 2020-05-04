for ns in $(ip netns list | awk '{print $1}'); do sudo ip netns delete $ns; done
