#!/bin/bash

vmname="win10"

if ps -ef | grep qemu-system-x86_64 | grep -q multifunction=on; then
echo "A passthrough VM is already running." &
exit 1

else

# use pulseaudio
export QEMU_AUDIO_DRV=pa
export QEMU_PA_SAMPLES=8192
export QEMU_AUDIO_TIMER_PERIOD=99
export QEMU_PA_SERVER=/run/user/1000/pulse/native

cp /usr/share/OVMF/OVMF_VARS.fd /tmp/my_vars.fd

qemu-system-x86_64 \
-runas root \
-name $vmname,process=$vmname \
-machine type=q35,accel=kvm \
-cpu host,kvm=off \
-smp 8,sockets=1,cores=8,threads=1 \
-m 8G \
-rtc clock=host,base=localtime \
-vga none \
-nographic \
-serial none \
-parallel none \
-soundhw hda \
-usb \
-device usb-host,vendorid=0x045e,productid=0x076c \
-device usb-host,vendorid=0x045e,productid=0x0750 \
-device vfio-pci,host=08:00.0,multifunction=on \
-device vfio-pci,host=08:00.1 \
-drive if=pflash,format=raw,readonly,file=/usr/share/OVMF/OVMF_CODE.fd \
-drive if=pflash,format=raw,file=/tmp/my_vars.fd \
-boot order=dc \
#-drive id=disk0,if=virtio,cache=none,format=raw,file=/dev/sda
#-netdev type=tap,id=net0,ifname=vmtap0,vhost=on \
#-device virtio-net-pci,netdev=net0,mac=00:16:3e:00:01:01
#-mem-path /dev/hugepages/

exit 0
fi

