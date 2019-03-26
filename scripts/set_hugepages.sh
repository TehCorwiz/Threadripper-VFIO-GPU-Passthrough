NODE=0
echo 4096 > /sys/devices/system/node/node${NODE}/*/hugepages-2048kB/nr_hugepages

