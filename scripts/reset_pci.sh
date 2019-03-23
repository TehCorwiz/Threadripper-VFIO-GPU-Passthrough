echo "1" | tee -a /sys/bus/pci/devices/0000\:08\:00.0/remove # <-GPU
echo "1" | tee -a /sys/bus/pci/devices/0000\:08\:00.1/remove # <-HDMI/DP audio device
echo “1” | tee -a /sys/bus/pci/rescan
lspci -vv | grep vfio -B 12

