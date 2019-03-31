#!/bin/sh -e


INTERFACE=enp4s0

sudo nmcli con add type bridge ifname br0
sudo nmcli con mod bridge-br0 bridge.stp no
sudo nmcli con add type bridge-slave ifname ${INTERFACE} master bridge-br0
#sudo reboot

