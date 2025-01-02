#!/bin/bash

# Variables for Server 2
NS1="NS1"
NS2="NS2"
NODE_IP=<IPX>
BRIDGE_SUBNET=172.16.1.0/24
BRIDGE_IP=172.16.1.1
IP1=172.16.1.2
IP2=172.16.1.3
TO_NODE_IP=<IPY>
TO_BRIDGE_SUBNET=172.16.0.0/24

# Create network namespaces
sudo ip netns add $NS1
sudo ip netns add $NS2

echo "Network namespaces created:"
ip netns show

# Create veth pairs
sudo ip link add veth10 type veth peer name veth11
sudo ip link add veth20 type veth peer name veth21

echo "Veth pairs created:"
ip link show type veth

# Assign veth interfaces to namespaces
sudo ip link set veth11 netns $NS1
sudo ip link set veth21 netns $NS2

# Assign IP addresses to namespace interfaces
sudo ip netns exec $NS1 ip addr add $IP1/24 dev veth11
sudo ip netns exec $NS2 ip addr add $IP2/24 dev veth21

# Bring up interfaces in namespaces
sudo ip netns exec $NS1 ip link set dev veth11 up
sudo ip netns exec $NS2 ip link set dev veth21 up

# Create and configure the bridge
sudo ip link add br0 type bridge
echo "Bridge created:"
ip link show type bridge

sudo ip link set dev veth10 master br0
sudo ip link set dev veth20 master br0
sudo ip addr add $BRIDGE_IP/24 dev br0
sudo ip link set dev br0 up
sudo ip link set dev veth10 up
sudo ip link set dev veth20 up

# Enable loopback interfaces in namespaces
sudo ip netns exec $NS1 ip link set lo up
sudo ip netns exec $NS2 ip link set lo up

# Verify IP configuration
sudo ip netns exec $NS1 ip a
sudo ip netns exec $NS2 ip a

# Set default routes in namespaces
sudo ip netns exec $NS1 ip route add default via $BRIDGE_IP dev veth11
sudo ip netns exec $NS2 ip route add default via $BRIDGE_IP dev veth21

# Add route to the other bridge subnet
sudo ip route add $TO_BRIDGE_SUBNET via $TO_NODE_IP dev eth0

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Configure NAT masquerading
sudo iptables -t nat -A POSTROUTING -s $BRIDGE_SUBNET ! -o br0 -j MASQUERADE
echo "NAT masquerading enabled."
